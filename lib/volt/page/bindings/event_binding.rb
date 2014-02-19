require 'volt/page/bindings/base_binding'

# TODO: We need to figure out how we want to wrap JS events
class JSEvent
  attr_reader :js_event
  def initialize(js_event)
    @js_event = js_event
  end

  def key_code
    `this.js_event.keyCode`
  end

  def stop
    # puts "STOPPING"
    # `this.js_event.stopPropagation();`
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

    handler = Proc.new do |js_event|
      event = JSEvent.new(js_event)
      event.stop if event_name == 'submit'

      # Call the proc the user setup for the event in context,
      # pass in the wrapper for the JS event
      result = @context.instance_exec(event, &call_proc)
    end

    @listener = @page.events.add(event_name, self, handler)
  end

  # Remove the event binding
  def remove
    # puts "REMOVE EL FOR #{@event}"
    @page.events.remove(@event_name, self)
  end
end
