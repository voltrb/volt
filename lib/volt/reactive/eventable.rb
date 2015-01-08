module Volt
  # Listeners are returned from #on on a class with Eventable included.
  # Listeners can be stopped by calling #remove
  class Listener
    def initialize(klass, events, callback)
      @klass    = klass
      @events    = events
      @callback = callback
    end

    def call(*args)
      @callback.call(*args) unless @removed
    end

    # Call the callback with self set to instance
    def instance_call(instance, *args)
      instance.instance_exec(*args, &@callback)
    end

    def remove
      @removed = true

      @events.each do |event|
        @klass.remove_listener(event, self)
      end

      # Make things easier on the GC
      @klass    = nil
      @callback = nil
    end

    def inspect
      "<Listener:#{object_id} events=#{@events}>"
    end
  end

  # Include Eventable to add a basic event/trigger system to a class.  Listeners can be
  # added with #on(event_name) { ... }  Events can be triggered with #trigger!
  module Eventable
    # Sets up a listener on the class the Eventable module was included in.
    # event should be a string or symbol.  When something calls #trigger!(event_name) on
    # the class, it will trigger any listener with the same event name.
    #
    # returns: a listener that has a #remove method to stop the listener.
    def on(*events, &callback)
      raise '.on requires an event' if events.size == 0

      listener = Listener.new(self, events, callback)

      @listeners        ||= {}

      events.each do |event|
        event             = event.to_sym
        @listeners[event] ||= []
        @listeners[event] << listener

        first_for_event = @listeners[event].size == 1
        first           = first_for_event && @listeners.size == 1

        # Let the included class know that an event was registered. (if it cares)
        if self.respond_to?(:event_added)
          # call event added passing the event, the scope, and a boolean if it
          # is the first time this event has been added.
          event_added(event, first, first_for_event)
        end
      end

      listener
    end


    # Triggers event on the class the module was includeded.  Any .on listeners
    # will have their block called passing in *args.
    def trigger!(event, *args)
      event = event.to_sym

      if @listeners && @listeners[event]
        # TODO: We have to dup here because one trigger might remove another
        @listeners[event].dup.each do |listener|
          # Call the event on each listener
          listener.call(*args)
        end
      end
    end

    # Stops the listener returned by calling .on(:event_name)  Triggers #event_removed
    # if there are no more listeners for that event.
    def remove_listener(event, listener)
      event = event.to_sym

      fail "Unable to delete #{event} from #{inspect}" unless @listeners && @listeners[event]

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
        event_removed(event, last, last_for_event)
      end
    end
  end
end
