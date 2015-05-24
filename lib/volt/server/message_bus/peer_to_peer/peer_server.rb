# The peer server opens a socket on a port that other instances (volt server,
# runner, etc...)
require 'socket'
require 'thread'
require 'volt/server/message_bus/peer_to_peer/peer_connection'

module Volt
  module MessageBus
    class NoAvailablePortException < Exception ; end
    class PeerServer
      def initialize(message_bus)
        @message_bus = message_bus

        setup_port_ranges

        ip = Volt.config.message_bus.try(:bind_ip)
        begin
          @server = TCPServer.new(random_port!)
        rescue Errno::EADDRINUSE => e
          # Keep trying ports until we find one that is not in use, or the pool
          # runs out of ports.
          retry
        end

        run_server
      end

      def run_server
        @main_thread = Thread.new do
          # Start the server
          loop do
            Thread.start(@server.accept) do |socket|
              peer_connection = PeerConnection.new(socket, nil, nil,
                @message_bus, true)

              @message_bus.add_peer_connection(peer_connection)
            end
          end
        end
      end

      def stop
        @main_thread.kill
      end

      def port
        @server.addr[1]
      end

      private
        def setup_port_ranges
          port_ranges = Volt.config.message_bus.try(:bind_port_ranges)

          if port_ranges
            # Expand any ranges, then sample one from the array
            @ports_pool = port_ranges.to_a.map {|v| v.is_a?(Range) ? v.to_a : v }.flatten
          else
            # port 0, which tells TCPServer to select any random port.
            @ports_pool = [0]
          end
        end

        def random_port!
          port = @ports_pool.sample

          unless port
            # no available ports left
            raise NoAvailablePortException, 'no ports available in Volt.config.message_bus.bind_port_ranges'
          end

          # remove from the pool
          @ports_pool.delete(port)

          port
        end
    end
  end
end
