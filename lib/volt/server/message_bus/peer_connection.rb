# The peer client manages the connection to a peer.

require 'thread'

module Volt
  class MessageBus
    class PeerConnection
      # The server id for the connected server
      attr_reader :peer_server_id

      def initialize(socket, ip, port, message_bus, server=false)
        puts "Connected to #{ip} - #{port}"
        @message_bus = message_bus
        @ip = ip
        @port = port
        @server = server
        @socket = socket
        @server_id = message_bus.server_id
        @message_queue = SizedQueue.new(500)
        @reconnect_mutex = Mutex.new

        failed = false
        begin
          if server
            # Wait for announcement
            @peer_server_id = @socket.gets.strip
            @socket.puts(@server_id)

            # Make sure we aren't already connected
            @message_bus.remove_duplicate_connections
          else
            # Announce
            @socket.puts(@server_id)
            @peer_server_id = @socket.gets.strip
          end
        rescue IOError => e
          failed = true
        end

        # Don't connect to self
        if @failed || @peer_server_id == @server_id
          # Close the connection
          @socket.close
          return
        end

        Thread.new do
          # Listen for messages in a new thread
          listen
        end

        Thread.new do
          run_worker
        end
      end

      def send_message(message)
        @message_queue.push(message)
      end

      def run_worker
        while (message = @message_queue.pop)
          break if message == :QUIT

          begin
            @socket.puts(message)
          rescue Errno::ECONNREFUSED, Errno::EPIPE => e
            if reconnect!
              retry
            else
              # Unable to reconnect, die
              break
            end
          end
        end
      end

      # We are connected elsewhere, remove the connection
      def disconnect
        @disconnected = true
        @message_queue.push(:QUIT)
        @socket.close
      end

      def listen
        loop do
          begin
            while (message = @socket.gets)
              break if @disconnected
              @message_bus.handle_message(message)
            end
          rescue Errno::ECONNRESET, Errno::EPIPE => e
            # handle below
          end

          if !@disconnected && !@server
            # Connection was dropped, try to reconnect
            connected = reconnect!

            # Couldn't reconnect, die
            break unless connected
          end
        end
      end


      # Because servers can have many ips, we try the various ip's until we are
      # able to connect to one.
      # @param [Array] an array of ip strings
      def self.connect_to(message_bus, ips, port)
        ips.split(',').each do |ip|
          begin
            socket = TCPSocket.new(ip, port)
            return PeerConnection.new(socket, ip, port, message_bus)
          rescue Errno::ECONNREFUSED => e
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
        puts "RECONNECT"

        # Don't reconnect on the server instances
        return false if @server
        @reconnect_mutex.synchronize do
          puts "START RECONNECT"
          loop do
            # Server is no longer reporting as alive, give up on reconnecting
            unless still_alive?
              puts "DIED: #{@ip} - #{@port}"
              # Unable to connect, let peer connection die
              @message_bus.remove_peer_connection(self)
              return false
            end

            failed = false
            begin
              puts "reconnect to #{@ip}:#{@port}"
              socket = TCPSocket.new(@ip, @port)
            rescue Errno::ECONNREFUSED, SocketError => e
              # Unable to cnnect, wait 10, try again
              sleep 10
              failed = true
            end

            unless failed
              # Reconnected
              puts "reconnected to #{@ip}:#{@port}"
              return true
            end
          end
        end
      end
    end
  end
end