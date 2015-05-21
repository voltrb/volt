# The peer server is connected to from other instances (volt server, runner,
# etc...)
require 'socket'
require 'thread'
require 'volt/server/message_bus/peer_connection'

module Volt
  class MessageBus
    class PeerServer
      def initialize(message_bus)
        @message_bus = message_bus
        @server = TCPServer.new(0)

        Thread.new do
          # Start the server

          loop do
            Thread.start(@server.accept) do |socket|
              peer_connection = PeerConnection.new(socket, nil, nil, @message_bus, true)
              @message_bus.add_peer_connection(peer_connection)
            end
          end
        end
      end

      def port
        @server.addr[1]
      end
    end
  end
end
