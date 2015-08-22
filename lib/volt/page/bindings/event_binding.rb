require 'volt/page/bindings/base_binding'

module Volt
  # TODO: We need to figure out how we want to wrap JS events
  class JSEvent
    attr_reader :js_event

    # The Volt controller that dispatched the event.
    attr_accessor :controller

    def initialize(js_event)
      @js_event = js_event
    end

    def key_code
      `self.js_event.keyCode`
    end

    def stop!
      `self.js_event.stopPropagation();`
    end

    def prevent_default!
      `self.js_event.preventDefault();`
    end

    def target
      `self.js_event.toElement || self.js_event.target`
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


      handler = proc do |js_event, *args|
        event = JSEvent.new(js_event)
        event.prevent_default! if event_name == 'submit'

        # When the event is triggered via ```trigger(..)``` in a controller,
        # it will pass its self as the first argument.  We set that to
        # ```controller``` on the event, so it can be easily accessed.
        if args[0].is_a?(Volt::ModelController)
          args = args.dup
          event.controller = args.shift
        end

        args << event

        self.class.call_handler_proc(@context, call_proc, event, args)
      end

      @listener = browser.events.add(@event_name, self, handler)
    end

    def self.call_handler_proc(context, call_proc, event, args)
      # When the EventBinding is compiled, it converts a passed in string to
      # get a Method:
      #
      # Example:
      #   <a e-awesome="some_method">...</a>
      #
      # The call_proc will be passed in as:  Proc.new { method(:some_method) }
      #
      # So first we call the call_proc, then that returns a method (or proc),
      # which we call passing in the arguments based on the arity.
      #
      # If the e- binding has arguments passed to it, we just use those.
      result = context.instance_exec(event, &call_proc)
      # Trim args to match arity

      # The proc returned a
      if result && result.is_a?(Method)
        args = args[0...result.arity]

        result.call(*args)
      end

      result
    end

    # Remove the event binding
    def remove
      browser.events.remove(@event_name, self)
    end
  end
end
