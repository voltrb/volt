require 'volt/reactive/eventable'

module Volt
  # ClassEventable behaves like Eventable, except events can be bound with a class #on method.
  # When triggered on an instance, the self in the block will be the instance it was triggered
  # on.  This allows classes to easy setup listeners.
  #
  # Example:
  #    class Post
  #      on(:create) do
  #        deny if owner?
  #      end
  #    end
  module ClassEventable
    module ClassMethods
      # Eventable also provides a static version of on, which allows you to setup on
      # events at the class level.  When the event triggers, self will be set to the
      # instance it was triggered on.
      def on(*events, &callback)
        raise '.on requires an event' if events.size == 0

        listener = Listener.new(self, events, callback)

        self.__listeners__ ||= {}

        events.each do |event|
          listeners = self.__listeners__
          listeners[event] ||= []
          listeners[event] << listener
        end
      end

      def remove_listener(event, listener)
        listeners = self.__listeners__
        if listeners
          listeners[event].delete(listener)

          if listeners[event].size == 0
            # No registered listeners now on this event
            listeners.delete(event)
          end
        end
      end
    end

    module InstanceMethods
      # Extend trigger! to also trigger class listeners
      def trigger!(event, *args)
        event = event.to_sym

        super

        if (klass_listeners = self.class.__listeners__)
          klass_listeners[event].dup.each do |listener|
            # Call each class listener with self set to the current instance
            listener.instance_call(self, *args)
          end
        end
      end
    end

    def self.included(base)
      base.class_attribute :__listeners__

      # Include the base eventable so the class can be triggered on
      base.send :include, Volt::Eventable
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end
  end
end