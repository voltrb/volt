require 'volt/reactive/eventable'
require 'volt/server/message_bus/base_message_bus'

module Volt
  class MessageBusClientProxy < MessageBus::BaseMessageBus
    include Eventable

    # Custom listener class, proxying Eventable#Listener since
    # we have to inform remote on the removal of a listener
    class ListenerProxy
      def initialize(target, remote_listener_id)
        @target = target
        @listener_id = remote_listener_id
      end

      # custom remove implementation: also calls task to remove listener
      # returns promise of the task
      def remove
        @target.remove
        MessageBusTasks.remove(@listener_id)
      end

      # proxy all other methods
      def method_missing(method, *args, &block)
        @target.send(method, *args, &block)
      end
    end

    # Use subscribe instead of on provided in Eventable
    alias_method :subscribe, :on
    alias_method :eventable_on, :on # this is only for obtaining the original
                                    # method behaviour although overriding it

    # Adds a reference to the client app from this proxy
    def initialize(volt_app)
      @volt_app = volt_app

      # Called when the backend informs us about a new subscribed message bus event
      @volt_app.channel.on('message') do |*args|
        if args.delete_at(0) == 'message_bus_event'
          trigger!(*args)
        end
      end
    end

    # Publishes a message into the message bus, returns a promise
    def publish(channel_name, message)
      MessageBusTasks.publish(channel_name, message)
    end

    # overwrites subscribe and on from Eventable to register subscription in message bus first
    # this will return a promise resolving to ListenerProxy, so you can call ".remove" on it directly
    def on(*events, &block)
      # Promise to resolve on working subscription, giving you a listener to remove
      subscription_promise = Promise.new

      MessageBusTasks.subscribe(*events).then do |remote_listener_id|
        # Register event locally, TODO: direclty pass block
        listener = eventable_on(*events) do |*params|
          block.call(*params)
        end

        # Resolve promise with object of ListenerProxy to enable removing of listener
        subscription_promise.resolve(ListenerProxy.new(listener, remote_listener_id))
      end.fail do |error|
        # Tell promise about failure
        subscription_promise.reject(error)
      end

      subscription_promise
    end

    # Unnecessary on clients
    def disconnect!
      raise "You cannot disconnect from message bus on the client. 'disconnect!' is only available on the server."
    end

  end
end