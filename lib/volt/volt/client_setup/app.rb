# The following setup handles setting up the app on the client.
# Currently, this only sets up the message bus for client usage

require 'volt/page/message_bus_client_proxy'

module Volt
  module ClientSetup
    module App

      # Registers app.message_bus as a proxyfied websocket endpoint to the message bus
      def start_message_bus
        @message_bus = MessageBusClientProxy.new(self)
      end
    end
  end
end
