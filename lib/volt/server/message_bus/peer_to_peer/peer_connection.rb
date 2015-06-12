# PeerConnection manages the connection to a peer, it takes a socket and
# optionally the ip and port it connected to.  If ip and port are given, it
# will try to reconnect until the server is marked as dead (as checked by
# message_bus.still_alive?)

require 'thread'
require 'volt/server/message_bus/peer_to_peer/socket_with_timeout'
require 'volt/server/message_bus/message_encoder'

module Volt
  module MessageBus
    class PeerConnection
      CONNECT_TIMEOUT = 2
      # The server id for the connected server
      attr_reader :peer_server_id, :socket

      def initialize(socket, ip, port, message_bus, server=false)
        @message_bus = message_bus
        @ip = ip
        @port = port
        @server = server
        @socket = socket
        @server_id = message_bus.server_id
        @message_queue = SizedQueue.new(500)
        @reconnect_mutex = Mutex.new

        # The encoder handles things like formatting and encryption
        @message_encoder = MessageEncoder.new


        failed = false
        begin
          if server
            # Wait for announcement
            @peer_server_id = @message_encoder.receive_message(@socket)
            @message_encoder.send_message(@socket, @server_id)
          else
            # Announce
            @message_encoder.send_message(@socket, @server_id)
            @peer_server_id = @message_encoder.receive_message(@socket)
          end
        rescue IOError => e
          failed = true
        end

        # Make sure we aren't already connected
        @message_bus.remove_duplicate_connections

        # Don't connect to self
        if @failed || @peer_server_id == @server_id
          # Close the connection
          close
          return
        end

        @listen_thread = Thread.new do
          # Listen for messages in a new thread
          listen
        end

        @worker_thread = Thread.new do
          run_worker
        end
      end

      # Close the socket, kill worker threads, and remove from
      # message_bus's peer_connections
      def disconnect
        @disconnected = true
        @message_queue.push(:QUIT)
        begin
          @socket.close
        rescue => e
          # Ignore close error, since we may not be connected
        end

        @listen_thread.kill
        @worker_thread.kill

        @message_bus.remove_peer_connection(self)
      end

      def publish(message)
        @message_queue.push(message)
      end

      def run_worker
        while (message = @message_queue.pop)
          break if message == :QUIT

          begin
            @message_encoder.send_message(@socket, message)
            # 'Error: closed stream' comes in sometimes
          rescue Errno::ECONNREFUSED, Errno::ENETUNREACH, Errno::EPIPE, IOError => e # was also rescuing Error
            if reconnect!
              retry
            else
              # Unable to reconnect, die
              break
            end
          end
        end
      end


      def listen
        loop do
          begin
            while (message = @message_encoder.receive_message(@socket))
              # puts "Message: #{message.inspect}"
              break if @disconnected
              @message_bus.handle_message(message)
            end

            # Got nil from socket
          rescue Errno::ECONNRESET, Errno::ENETUNREACH, Errno::EPIPE, IOError => e
            # handle below
          end

          if !@disconnected && !@server
            # Connection was dropped, try to reconnect
            connected = reconnect!

            # Couldn't reconnect, die
            break unless connected
          else
            break
          end
        end
      end


      # Because servers can have many ips, we try the various ip's until we are
      # able to connect to one.
      # @param [Array] an array of ip strings
      def self.connect_to(message_bus, ips, port)
        ips.split(',').each do |ip|
          begin
            socket = SocketWithTimeout.new(ip, port, CONNECT_TIMEOUT)
            return PeerConnection.new(socket, ip, port, message_bus)
          rescue Errno::ECONNREFUSED, Errno::ENETUNREACH, Errno::ETIMEDOUT => e
            # Unable to connect, next
            next
          end
        end

        return false
      end

      private

      def still_alive?
        @message_bus.still_alive?(@peer_server_id)
      end

      def reconnect!
        # Don't reconnect on the server instances
        return false if @server
        @reconnect_mutex.synchronize do
          loop do
            # Server is no longer reporting as alive, give up on reconnecting
            unless still_alive?
              # Unable to connect, let peer connection die
              disconnect
              return false
            end

            failed = false
            begin
              socket = SocketWithTimeout.new(@ip, @port, CONNECT_TIMEOUT)
            rescue Errno::ECONNREFUSED, SocketError => e
              # Unable to cnnect, wait 10, try again
              sleep 10
              failed = true
            end

            unless failed
              # Reconnected
              return true
            end
          end
        end
      end
    end
  end
end