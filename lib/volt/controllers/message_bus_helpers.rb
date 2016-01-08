# Current status of this: concept..

# Todo: How to add this to controller lifecycle management (see method todo's)
# Adds a method 'message_bus_subscription' to your controller which makes it easier to
# subscribe to message bus
# Usage: message_bus_subscription :my_event, :my_method
# You can also pass a proc instead of a method. The instance method or proc will be called
# every time the event is fired. The listeners will be removed automatically as soon as the
# controller is not needed anymore.

module Volt
  module MessageBusHelpers
    module ClassMethods
      def message_bus_subscription event, callback
        callback = callback.to_sym unless callback.is_a?(Proc)
        @message_bus_subscriptions ||= []
        @message_bus_subscriptions << {event: event, callback: callback}
      end
    end

    def self.included(base)
      base.extend ClassMethods
    end

    # todo: Call this method automatically on controller startup, but only once!
    # before_action won't fit here, and hook in initialize either:
    # the block is executed many times (5x) (why?) on start up / with a test on main_controller
    def register_message_bus
      @message_bus_listeners = []
      subscriptions = self.class.instance_variable_get :@message_bus_subscriptions
      subscriptions ||= []

      subscriptions.each do |subscription|
        @message_bus_listeners << Volt.current_app.message_bus.on(subscription[:event]) do |*params|
          case subscription[:callback]
            when Symbol
              send(subscription[:callback])
            when Proc
              instance_eval(&subscription[:callback])
          end
        end
      end
    end

    # todo: call this automatically once controller is not needed anymore
    # how to integrate this into controller lifecycle management?
    def remove_message_bus_listeners
      return if @message_bus_listeners.nil?
      @message_bus_listeners.each &:remove
    end
  end
end