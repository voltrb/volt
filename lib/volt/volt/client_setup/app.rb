# The following setup handles setting up the app on the client.
# Currently, this only sets up the message bus for client usage

require 'volt/page/message_bus_client_adapter'

module Volt
  module ClientSetup
    module App

      # Registers app.message_bus as a websocket endpoint / adapter to the message bus
      def start_message_bus
        @message_bus = MessageBusClientAdapter.new(self)
      end
    end
  end
end
