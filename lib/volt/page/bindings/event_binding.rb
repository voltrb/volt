require 'volt/page/bindings/base_binding'

module Volt
  # TODO: We need to figure out how we want to wrap JS events
  class JSEvent
    attr_reader :js_event

    def initialize(js_event)
      @js_event = js_event
    end

    def key_code
      `this.js_event.keyCode`
    end

    def stop!
      `this.js_event.stopPropagation();`
    end

    def prevent_default!
      `this.js_event.preventDefault();`
    end

    def target
      `this.js_event.toElement`
    end
  end

  class EventBinding < BaseBinding
    attr_accessor :context, :binding_name

    def initialize(page, target, context, binding_name, event_name, call_proc)
      super(page, target, context, binding_name)
      @event_name = event_name

      handler = proc do |js_event|
        event = JSEvent.new(js_event)
        event.prevent_default! if event_name == 'submit'

        # Call the proc the user setup for the event in context,
        # pass in the wrapper for the JS event
        result = @context.instance_exec(event, &call_proc)
      end

      @listener = @page.events.add(event_name, self, handler)
    end

    # Remove the event binding
    def remove
      @page.events.remove(@event_name, self)
    end
  end
end
