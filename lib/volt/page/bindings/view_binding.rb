require 'volt/page/bindings/base_binding'
require 'volt/page/template_renderer'
require 'volt/page/bindings/view_binding/grouped_controllers'
require 'volt/page/bindings/view_binding/view_lookup_for_path'
require 'volt/page/bindings/view_binding/controller_handler'

module Volt
  class ViewBinding < BaseBinding
    # @param [String]     binding_in_path is the path this binding was rendered from.  Used to
    #                     lookup paths in ViewLookupForPath
    # @param [String|nil] content_template_path is the path to the template for the content
    #                     provided in the tag.
    def initialize(volt_app, target, context, binding_name, binding_in_path, getter, content_template_path = nil)
      super(volt_app, target, context, binding_name)

      @content_template_path = content_template_path

      # Setup the view lookup helper
      @view_lookup = Volt::ViewLookupForPath.new(volt_app.templates, binding_in_path)

      @current_template = nil

      # Run the initial render
      @computation      = lambda do
        # Don't try to render if this has been removed
        if @context
          # Render
          update(*@context.instance_eval(&getter))
        end
      end.watch!
    end

    # update is called when the path string changes.
    def update(path, section_or_arguments = nil, options = {})
      Computation.run_without_tracking do
        @options = options

        # A blank path needs to load a missing template, otherwise it tries to load
        # the same template.
        path     = path.blank? ? '---missing---' : path

        section    = nil
        @arguments = nil

        if section_or_arguments.is_a?(String)
          # Render this as a section
          section = section_or_arguments
        else
          # Use the value passed in as the default arguments
          @arguments = section_or_arguments

          # Include content_template_path in attrs
          if @content_template_path
            @arguments ||= {}
            @arguments[:content_template_path] = @content_template_path
            @arguments[:content_controller] = @context
          end
        end

        # Sometimes we want multiple template bindings to share the same controller (usually
        # when displaying a :Title and a :Body), this instance tracks those.
        if @options && (controller_group = @options[:controller_group])
          # Setup the grouped controller for the first time.
          @grouped_controller = GroupedControllers.new(controller_group)
        end

        # If a controller is already starting, but not yet started, then remove it.
        remove_starting_controller

        full_path, controller_path = @view_lookup.path_for_template(path, section)

        if full_path
          @starting_controller_handler, generated_new, chain_stopped = create_controller_handler(full_path, controller_path)

          # Check if chain was stopped when the action ran
          if chain_stopped
            # An action stopped the chain.  When this happens, we stop running here.
            remove_starting_controller
          else
            # None of the actions stopped the chain
            # Wait until the controller is loaded before we actually render.
            @waiting_for_load = -> { @starting_controller_handler.controller.loaded? }.watch_until!(true) do
              render_next_template(full_path, path)
            end

            queue_clear_grouped_controller
          end
        else
          # if we don't have a full path, then we have a missing template
          render_next_template(full_path, path)
        end
      end
    end

    # Called when the next template is ready to render
    def render_next_template(full_path, path)
      remove_current_controller_and_template

      # Switch the current template
      @current_controller_handler = @starting_controller_handler
      @starting_controller_handler = nil

      # Also track the current controller directly
      @controller = @current_controller_handler.controller if full_path

      render_template(full_path || path)
    # rescue => e
    #   Volt.logger.error("Error during render of template at #{path}: #{e.inspect}")
    #   Volt.logger.error(e.backtrace)
    end

    def stop_waiting_for_load
      if @waiting_for_load
        @waiting_for_load.stop
        @waiting_for_load = nil
      end
    end

    # On the next tick, we clear the grouped controller so that any changes to template paths
    # will create a new controller and trigger the action.
    def queue_clear_grouped_controller
      if Volt.in_browser?
        # In the browser, we want to keep a grouped controller around during a single run
        # of the event loop.  To make that happen, we clear it on the next tick.
        `setImmediate(function() {`
        clear_grouped_controller
        `});`
      else
        # For the backend, clear it immediately
        clear_grouped_controller
      end
    end

    def clear_grouped_controller
      if @grouped_controller
        @grouped_controller.clear
        @grouped_controller = nil
      end
    end

    def remove_current_controller_and_template
      # Remove existing controller and template and call _removed
      if @current_controller_handler
        @current_controller_handler.call_action('before', 'remove')
      end

      if @current_template
        @current_template.remove
        @current_template = nil
      end

      if @current_controller_handler
        @current_controller_handler.call_action('after', 'remove')
      end

      if @grouped_controller && @current_controller_handler
        # We remove the controller after all of the current rendering is done.
        Timers.next_tick do
          # Remove a reference for the controller in the group.
          @grouped_controller.remove(@current_controller_handler.controller.class)
        end
      end

      @controller = nil
      @current_controller_handler = nil
    end

    def remove_starting_controller
      # Clear any previously running wait for loads.  This is for when the path changes
      # before the view actually renders.
      stop_waiting_for_load

      if @starting_controller_handler
        # Only call the after_..._removed because the dom never loaded.
        @starting_controller_handler.call_action('after', 'removed')
        @starting_controller_handler = nil
      end
    end

    # Create controller handler loads up a controller inside of the controller handler for the paths
    def create_controller_handler(full_path, controller_path)
      # If arguments is nil, then an blank SubContext will be created
      args = [SubContext.new(@arguments, nil, true)]

      # get the controller class and action
      controller_class, action = ControllerHandler.get_controller_and_action(controller_path)

      generated_new = false
      new_controller = proc do
        # Mark that we needed to generate a new controller instance (not reused
        # from the group)
        generated_new = true
        # Setup the controller
        controller_class.new(@volt_app, *args)
      end

      # Fetch grouped controllers if we're grouping
      if @grouped_controller
        # Find the controller in the group, or create it
        controller = @grouped_controller.lookup_or_create(controller_class, &new_controller)
      else
        # Just create the controller
        controller = new_controller.call
      end

      handler = ControllerHandler.fetch(controller, action)

      if generated_new
        # Call the action
        stopped = handler.call_action

        controller.instance_variable_set('@chain_stopped', true) if stopped
      else
        stopped = controller.instance_variable_get('@chain_stopped')
      end

      [handler, generated_new, stopped]
    end

    # The context for templates can be either a controller, or the original context.
    def render_template(full_path)
      @current_template = TemplateRenderer.new(@volt_app, @target, @controller, @binding_name, full_path)

      call_ready
    end

    def call_ready
      if @controller
        # Set the current section on the controller if it wants so it can manipulate
        # the dom if needed.
        # Only assign sections for action's, so we don't get AttributeSections bound
        # also.
        if @controller.respond_to?(:section=)
          dom_section = @current_template.dom_section

          # Only assign dom sections that can be manipulated via the dom (so not the title for example)
          @controller.section = dom_section unless dom_section.is_a?(Volt::AttributeSection)
        end

        # Call the ready callback on the controller
        @current_controller_handler.call_action(nil, 'ready')
      end
    end

    # Called when the binding is removed from the page
    def remove
      # Cleanup any starting controller
      remove_starting_controller

      @computation.stop
      @computation = nil

      remove_current_controller_and_template

      super
    end
  end
end
