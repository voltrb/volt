module Volt
  class DocumentEvents
    def initialize
      @events = {}
    end

    def add(event, binding, handler)
      # Track each document event based on the event, element id, then binding.object_id
      unless @events[event]
        # We haven't defined an event of type event yet, lets attach it to the
        # document.

        @events[event] = {}

        that = self

        `
        $('body').on(event, function(e) {
          that.$handle(event, e, e.target || e.originalEvent.target);
        });
      `

      end

      @events[event][binding.binding_name]                    ||= {}
      @events[event][binding.binding_name][binding.object_id] = handler
    end

    def handle(event_name, event, target)
      element = Element.find(target)

      loop do
        # Lookup the handler, make sure to not assume the group
        # exists.
        # TODO: Sometimes the event doesn't exist, but we still get
        # an event.
        handlers = @events[event_name]
        handlers = handlers[element.id] if handlers

        if handlers
          handlers.values.each do |handler|
            # Call each handler for this object
            handler.call(event)
          end
        end

        if element.size == 0
          break
        else
          element = element.parent
        end
      end

      nil
    end

    def remove(event, binding)
      # Remove the event binding
      @events[event][binding.binding_name].delete(binding.object_id)

      # if there are no more handlers for this binding_name (the html id), then
      # we remove the binding name hash
      if @events[event][binding.binding_name].size == 0
        @events[event].delete(binding.binding_name)
      end

      # if there are no more handlers in this event, we can unregister the event
      # from the document
      if @events[event].size == 0
        @events.delete(event)

        # Remove the event from the body
        `
          $('body').unbind(event);
        `
      end
    end
  end
end
