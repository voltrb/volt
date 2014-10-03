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

    first_for_event = @listeners[event].size == 1
    first = first_for_event && @listeners.size == 1

    # Let the included class know that an event was registered. (if it cares)
    if self.respond_to?(:event_added)
      # call event added passing the event, the scope, and a boolean if it
      # is the first time this event has been added.
      self.event_added(event, first, first_for_event)
    end

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

    raise "Unable to delete #{event} from #{self.inspect}" unless @listeners && @listeners[event]

    @listeners[event].delete(listener)

    last_for_event = @listeners[event].size == 0

    if last_for_event
      # No registered listeners now on this event
      @listeners.delete(event)
    end

    last = last_for_event && @listeners.size == 0

    # Let the class we're included on know that we removed a listener (if it cares)
    if self.respond_to?(:event_removed)
      # Pass in the event and a boolean indicating if it is the last event
      self.event_removed(event, last, last_for_event)
    end
  end
end