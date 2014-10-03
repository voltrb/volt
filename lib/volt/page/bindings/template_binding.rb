require 'volt/page/bindings/base_binding'
require 'volt/page/template_renderer'
require 'volt/page/bindings/template_binding/grouped_controllers'

class TemplateBinding < BaseBinding
  def initialize(page, target, context, binding_name, binding_in_path, getter)
    super(page, target, context, binding_name)

    # Binding in path is the path for the template this binding is in
    setup_path(binding_in_path)

    @current_template = nil

    @getter = getter

    # Run the initial render
    @computation = -> { update(*@context.instance_eval(&getter)) }.watch!
  end

  def setup_path(binding_in_path)
    path_parts = binding_in_path.split('/')
    @collection_name = path_parts[0]
    @controller_name = path_parts[1]
    @page_name = path_parts[2]
  end

  # Returns true if there is a template at the path
  def check_for_template?(path)
    @page.templates[path]
  end

  # Takes in a lookup path and returns the full path for the matching
  # template.  Also returns the controller and action name if applicable.
  #
  # Looking up a path is fairly simple.  There are 4 parts needed to find
  # the html to be rendered.  File paths look like this:
  # app/{component}/views/{controller_name}/{view}.html
  # Within the html file may be one or more sections.
  # 1. component (app/{comp})
  # 2. controller
  # 3. view
  # 4. sections
  #
  # When searching for a file, the lookup starts at the section, and moves up.
  # when moving up, default values are provided for the section, then view/section, etc..
  # until a file is either found or the component level is reached.
  #
  # The defaults are as follows:
  # 1. component - main
  # 2. controller - main
  # 3. view - main
  # 4. section - body
  def path_for_template(lookup_path, force_section=nil)
    parts = lookup_path.split('/')
    parts_size = parts.size

    default_parts = ['main', 'main', 'index', 'body']

    # When forcing a sub template, we can default the sub template section
    default_parts[-1] = force_section if force_section

    (5 - parts_size).times do |path_position|
      # If they passed in a force_section, we can skip the first
      next if force_section && path_position == 0

      full_path = [@collection_name, @controller_name, @page_name, nil]

      start_at = full_path.size - parts_size - path_position

      full_path.size.times do |index|
        if index >= start_at
          if part = parts[index-start_at]
            full_path[index] = part
          else
            full_path[index] = default_parts[index]
          end
        end
      end

      path = full_path.join('/')
      if check_for_template?(path)
        controller = nil

        # Don't return a controller if we are just getting another section
        # from the same controller
        if path_position >= 1
          # Lookup the controller
          controller = [full_path[0], full_path[1] + '_controller', full_path[2]]
        end
        return path, controller
      end
    end

    return nil, nil
  end

  def update(path, section_or_arguments=nil, options={})
    Computation.run_without_tracking do
      # Remove existing template and call _removed
      controller_send(:"#{@action}_removed") if @action && @controller
      @current_template.remove if @current_template

      @options = options

      # A blank path needs to load a missing template, otherwise it tries to load
      # the same template.
      path = path.blank? ? '---missing---' : path

      section = nil
      @arguments = nil

      if section_or_arguments.is_a?(String)
        # Render this as a section
        section = section_or_arguments
      else
        # Use the value passed in as the default arguments
        @arguments = section_or_arguments
      end

      # Sometimes we want multiple template bindings to share the same controller (usually
      # when displaying a :Title and a :Body), this instance tracks those.
      if @options && (controller_group = @options[:controller_group])
        @grouped_controller = GroupedControllers.new(controller_group)
      else
        clear_grouped_controller
      end

      full_path, controller_path = path_for_template(path, section)
      render_template(full_path, controller_path)

      queue_clear_grouped_controller
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
      `})`
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

  # The context for templates can be either a controller, or the original context.
  def render_template(full_path, controller_path)
    if @arguments
      args = [SubContext.new(@arguments)]
    else
      args = []
    end

    @controller = nil

    # Fetch grouped controllers if we're grouping
    @controller = @grouped_controller.get if @grouped_controller

    # The action to be called and rendered
    @action = nil

    if @controller
      # Track that we're using the group controller
      @grouped_controller.inc if @grouped_controller
    else
      # Otherwise, make a new controller
      controller_class, @action = get_controller(controller_path)

      if controller_class
        # Setup the controller
        @controller = controller_class.new(*args)
      else
        @controller = ModelController.new(*args)
      end

      # Trigger the action
      controller_send(@action) if @action

      # Track the grouped controller
      @grouped_controller.set(@controller) if @grouped_controller
    end

    @current_template = TemplateRenderer.new(@page, @target, @controller, @binding_name, full_path)

    call_ready
  end

  def call_ready
    if @controller
      # Set the current section on the controller if it wants so it can manipulate
      # the dom if needed
      if @controller.respond_to?(:section=)
        @controller.section = @current_template.dom_section
      end

      controller_send(:"#{@action}_ready") if @action
    end
  end

  def remove
    clear_grouped_controller

    if @current_template
      # Remove the template if one has been rendered, when the template binding is
      # removed.
      @current_template.remove
    end

    super

    if @controller
      controller_send(:"#{@action}_removed") if @action

      @controller = nil
    end
  end

  private
    # Sends the action to the controller if it exists
    def controller_send(action_name)
      if @controller.respond_to?(action_name)
        @controller.send(action_name)
      end
    end

    # Fetch the controller class
    def get_controller(controller_path)
      return nil, nil unless controller_path && controller_path.size > 0

      action = controller_path[-1]

      # Get the constant parts
      parts = controller_path[0..-2].map {|v| v.gsub('-', '_').camelize }

      # Home doesn't get namespaced
      if parts.first == 'Main'
        parts.shift
      end

      # Do const lookups starting at object and working our way down.
      # So Volt::ProgressBar would lookup Volt, then ProgressBar on Volt.
      obj = Object
      parts.each do |part|
        if obj.const_defined?(part)
          obj = obj.const_get(part)
        else
          return nil
        end
      end

      return obj, action
    end

end
