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

    def initialize(volt_app, target, context, binding_name, event_name, call_proc)
      super(volt_app, target, context, binding_name)

      # Map blur/focus to focusout/focusin
      @event_name = case event_name
      when 'blur'
        'focusout'
      when 'focus'
        'focusin'
      else
        event_name
      end


      handler = proc do |js_event|
        event = JSEvent.new(js_event)
        event.prevent_default! if event_name == 'submit'

        # Call the proc the user setup for the event in context,
        # pass in the wrapper for the JS event
        result = @context.instance_exec(event, &call_proc)

        # The following doesn't work due to the promise already chained issue.
        # # Ignore native objects.
        # result = nil unless BasicObject === result

        # # if the result is a promise, log an exception if it failed and wasn't
        # # handled
        # if result.is_a?(Promise) && !result.next
        #   result.fail do |err|
        #     Volt.logger.error("EventBinding Error: promise returned from event binding #{@event_name} was rejected")
        #     Volt.logger.error(err)
        #   end
        # end

      end
      @listener = page.events.add(@event_name, self, handler)
    end

    # Remove the event binding
    def remove
      page.events.remove(@event_name, self)
    end
  end
end
