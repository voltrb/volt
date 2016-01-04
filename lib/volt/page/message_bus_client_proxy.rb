require 'volt/reactive/eventable'

module Volt
  class MessageBusClientProxy
    include Eventable

    # Use subscribe instead of on provided in Eventable
    alias_method :subscribe, :on

    # Adds a reference to the client app from this proxy
    def initialize(volt_app)
      @volt_app = volt_app
    end

    # publish should push out to all subscribed within the volt cluster.
    def publish(channel_name, message)
      puts 'publishing to channel...'
      MessageBusTasks.publish(channel_name, message).then do |result|
        puts 'success'
        puts result
      end.fail do |fail|
        puts 'error'
        puts fail
      end
    end

    # Unnecessary on clients
    def disconnect!
      raise "You cannot disconnect from message bus on the client. 'disconnect!' is only available on the server."
    end

  end
end