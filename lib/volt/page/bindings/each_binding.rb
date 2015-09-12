require 'volt/page/bindings/base_binding'

module Volt
  class InvalidObjectForEachBinding < Exception ; end

  class EachBinding < BaseBinding
    def initialize(volt_app, target, context, binding_name, getter, variable_name, index_name, template_name)
      super(volt_app, target, context, binding_name)

      @item_name     = variable_name
      @index_name    = index_name
      @template_name = template_name

      @templates = []

      @getter      = getter

      # Listen for changes
      @computation = lambda do
        begin
          value = @context.instance_eval(&@getter)
        rescue => e
          Volt.logger.error("EachBinding Error: #{e.inspect}")
          if RUBY_PLATFORM == 'opal'
            Volt.logger.error(`#{@getter}`)
          else
            Volt.logger.error(e.backtrace.join("\n"))
          end

          value = []
        end

        value
      end.watch_and_resolve!(
        method(:update),
        method(:getter_fail)
      )
    end

    # When a changed event happens, we update to the new size.
    def update(value)
      # Since we're checking things like size, we don't want this to be re-triggered on a
      # size change, so we run without tracking.
      Computation.run_without_tracking do
        # Adjust to the new size
        values = current_values(value)

        @value = values

        remove_listeners

        if @value.respond_to?(:on)
          @added_listener   = @value.on('added') { |position| item_added(position) }
          @removed_listener = @value.on('removed') { |position| item_removed(position) }
        end

        templates_size = nil
        values_size = nil

        Volt.run_in_mode(:no_model_promises) do
          templates_size = @templates.size

          unless values.respond_to?(:size)
            fail InvalidObjectForEachBinding, "Each binding's require an object that responds to size and [] methods.  The binding received: #{values.inspect}"
          end

          values_size    = values.size
        end

        # Start over, re-create all nodes
        (templates_size - 1).downto(0) do |index|
          item_removed(index)
        end
        0.upto(values_size - 1) do |index|
          item_added(index)
        end
      end
    end

    def item_removed(position)
      # Remove dependency
      @templates[position].context.locals[:_index_dependency].remove
      @templates[position].context.locals["_#{@item_name}_dependency".to_sym].remove

      @templates[position].remove_anchors
      @templates[position].remove
      @templates.delete_at(position)

      # Removed at the position, update context for every item after this position
      update_indexes_after(position)
    end

    def item_added(position)
      item_context = nil

      binding_name     = @@binding_number
      @@binding_number += 1

      if position >= @templates.size
        # Setup new bindings in the spot we want to insert the item
        dom_section.insert_anchor_before_end(binding_name)
      else
        # Insert the item before an existing item
        dom_section.insert_anchor_before(binding_name, @templates[position].binding_name)
      end

      # TODORW: parent: @value may change
      item_context                           = SubContext.new({ _index_value: position, parent: @value }, @context)
      item_context.locals[@item_name.to_sym] = proc do
        # Fetch only whats there currently, no promises.
        Volt.run_in_mode(:no_model_promises) do
          # puts "GET AT: #{item_context.locals[:_index_value]}"
          @value[item_context.locals[:_index_value]]
        end
      end

      position_dependency                    = Dependency.new
      item_context.locals[:_index_dependency] = position_dependency

      # Get and set index
      item_context.locals[:_index=]           = proc do |val|
        position_dependency.changed!
        item_context.locals[:_index_value] = val
      end

      # Get and set value
      value_dependency                    = Dependency.new
      item_context.locals["_#{@item_name}_dependency".to_sym] = value_dependency

      item_context.locals["#{@item_name}=".to_sym] = proc do |val|
        value_dependency.changed!
        @value[item_context.locals[:_index_value]] = val
      end

      # If the user provides an each_with_index, we can assign the lookup for the index
      # variable here.
      if @index_name
        item_context.locals[@index_name.to_sym] = proc do
          position_dependency.depend
          item_context.locals[:_index_value]
        end
      end

      item_template = TemplateRenderer.new(@volt_app, @target, item_context, binding_name, @template_name)
      @templates.insert(position, item_template)

      update_indexes_after(position)
    end

    # When items are added or removed in the middle of the list, we need
    # to update each templates index value.
    def update_indexes_after(start_index)
      size = @templates.size
      if size > 0
        start_index.upto(size - 1) do |index|
          @templates[index].context.locals[:_index=].call(index)
        end
      end
    end

    def current_values(values)
      return [] if values.is_a?(Model) || values.is_a?(Exception)
      values = values.attributes if values.respond_to?(:attributes)

      values
    end

    def remove_listeners
      if @added_listener
        @added_listener.remove
        @added_listener = nil
      end
      if @removed_listener
        @removed_listener.remove
        @removed_listener = nil
      end
    end

    # When this each_binding is removed, cleanup.
    def remove
      @computation.stop
      @computation = nil

      # Clear value
      @value       = []

      @getter = nil

      remove_listeners

      if @templates
        template_count = @templates.size
        template_count.times do |index|
          item_removed(template_count - index - 1)
        end
        # @templates.compact.each(&:remove)
        @templates = nil
      end

      super
    end
  end
end
