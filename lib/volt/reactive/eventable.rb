class Listener
  def initialize(klass, event, callback)
    @klass = klass
    @event = event
    @callback = callback
  end

  def call(*args)
    @callback.call(*args) unless @removed
  end

  def remove
    @removed = true

    @klass.remove_listener(@event, self)

    # Make things easier on the GC
    @klass = nil
    @callback = nil
  end

  def inspect
     "<Listener:#{object_id} event=#{@event}>"
   end
end

module Eventable
  def on(event, &callback)
    event = event.to_sym
    listener = Listener.new(self, event, callback)
    @listeners ||= {}
    @listeners[event] ||= []
    @listeners[event] << listener

    return listener
  end

  def trigger!(event, *args)
    event = event.to_sym

    return unless @listeners && @listeners[event]

    # TODO: We have to dup here because one trigger might remove another
    @listeners[event].dup.each do |listener|
      # Call the event on each listener
      listener.call(*args)
    end
  end

  def remove_listener(event, listener)
    event = event.to_sym

    puts "#{event.inspect} - #{listener.inspect}"

    raise "Unable to delete #{event} from #{self.inspect}" unless @listeners && @listeners[event]

    @listeners[event].delete(listener)

    puts @listeners.inspect

    last_for_event = @listeners[event].size == 0

    if last_for_event
      # No registered listeners now on this event
      @listeners.delete(event)
    end
  end
end