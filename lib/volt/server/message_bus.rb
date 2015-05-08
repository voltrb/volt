# The message bus in volt is responsible for passing messages between each of
# the running app servers (or console, etc...)  Since the database is assumed
# to be connected to from each instance, we write a record into the database
# with the ip of each active server and the current time.
#
# When a server connects, it creates a socket connection to all previous servers
# and announces its self.  Messages can then be sent over the bus.
#
# Each server should do MessageBus.start.  This will start it in its own thread.
require 'thread'
require 'securerandom'

require 'volt/reactive/eventable'
require 'volt/server/message_bus/server_tracker'
require 'volt/server/message_bus/peer_server'
require 'volt/server/message_bus/peer_connection'

# TODO: Right now the message bus uses threads, we should switch it to use a
# single thread and some form of select:
# https://practicingruby.com/articles/event-loops-demystified

module Volt
  class MessageBus
    include Eventable

    attr_reader :server_id
    attr_reader :page

    def initialize(page)
      # Generate a guid
      @server_id = SecureRandom.uuid
      @peer_connections = {}

      @page = page
      @peer_server = PeerServer.new(self)
      puts "Listen on: #{@peer_server.port.inspect}"
      @server_tracker = ServerTracker.new(page, @server_id, @peer_server.port)

      # Do the initial registration, and wait until its done before connecting
      # to peers.
      @server_tracker.register()

      connect_to_peers

      Thread.new do
        loop do
          send_message("HELLO FROM: #{@server_id}")
          sleep 5
        end
      end
    end

    def send_message(message)
      @peer_connections.keys.each do |peer|
        # Queue message on each peer
        peer.send_message(message)
      end
    end

    # Return an array of peer records.
    def peers
      instances = @page.store._active_volt_instances

      instances.where(server_id: {'$ne' => @server_id}).fetch.sync
    end

    def connect_to_peers
      peers.each do |peer|
        peer_connection = PeerConnection.connect_to(self, peer._ips, peer._port)

        if peer_connection
          add_peer_connection(peer_connection)
        else
          # remove if not alive anymore.
          still_alive?(peer._server_id)
        end
      end
    end

    def add_peer_connection(peer_connection)
      @peer_connections[peer_connection] = true
    end

    def remove_peer_connection(peer_connection)
      @peer_connections.delete(peer_connection)
    end

    # Called when a message comes in
    def handle_message(message)
      trigger!('message', message)
    end

    # We only want one connection between two instances, this loops through each
    # connection
    def remove_duplicate_connections
      peer_server_ids = {}

      # remove any we are connected to twice
      @peer_connections.keys.each do |peer|
        peer_id = peer.peer_server_id

        if peer_id
          # peer is connected

          if peer_server_ids[peer_id]
            # Peer is already connected somewhere else, remove connection
            peer.disconnect

            # remove the connection
            @peer_connections.delete(peer)
          else
            # Mark that we are connected
            peer_server_ids[peer_id] = true
          end
        end
      end
    end



      # Returns true if the server is still reporting as alive.
      def still_alive?(peer_server_id)
        # Unable to write to the socket, retry until the instance is no
        # longer marking its self as active in the database
        peer_table = @page.store._active_volt_instances
        peer = peer_table.where(server_id: peer_server_id).fetch_first.sync
        if peer
          # Found the peer, retry if it has reported in in the last 2
          # minutes.
          puts "Last Peer: #{peer._time} > #{(Time.now.to_i - (2*60))}"
          if peer._time > (Time.now.to_i - (2*60))
            # Peer reported in less than 2 minutes ago
            return true
          else
            # Delete the entry
            puts "Destroy Peer"
            peer.destroy
          end
        end

        false
      end

  end
end