# The message bus in volt is responsible for passing messages between each of
# the running app servers (or console, etc...)
# MessageBus::PeerToPeer is a simple message bus that automatically connects
# any volt instance using the same database into a cluster.  It can then do
# pub/sub between all instances.
#
# How It Works
# ------------
# Since the database is assumed to be connected to from each instance, we write
# a record into the database with the ip of each active server and the current
# time.
#
# When a server connects, it creates a socket connection to all previous servers
# and announces its self.  Messages can then be sent over the socket.  Messages
# are queued
#
# Limitations
# -----------
#
# While PeerToPeer should scale fine, it currently uses threads instead of
# an improved select library (epoll, kqueue, etc...) and non-blocking io.  The
# plan is to rewrite it to use non-blocking io at some point.
#
# Also, to simplify the subscription model, messages are sent to all instances
# reguardless of subscription status.  This greatly simplifies the
# implementation and adds some guarentees in a distributed system, at the cost
# of messages going to places they don't need to.  Since the primary use of the
# message bus is alerting other instances that data has changed, this limitation
# is not that big of an issues.  (Since the messages are small and usually need
# to go to most servers)  That said, you may want to consider another
# MessageBus for large scale deployments.
#
# The plan also is to improve the way messages are routed and to add other
# message passing paradigms like round robin receiver.
require 'thread'
require 'securerandom'

require 'volt/reactive/eventable'
require 'volt/server/message_bus/peer_to_peer/server_tracker'
require 'volt/server/message_bus/peer_to_peer/peer_server'
require 'volt/server/message_bus/peer_to_peer/peer_connection'
require 'volt/server/message_bus/base_message_bus'

# TODO: Right now the message bus uses threads, we should switch it to use a
# single thread and some form of select:
# https://practicingruby.com/articles/event-loops-demystified

module Volt
  module MessageBus
    class PeerToPeer < BaseMessageBus
      # How long without an update before we mark an instance as dead (in seconds)
      DEAD_TIME = 20
      include Eventable

      # Use subscribe instead of on provided in Eventable
      alias_method :subscribe, :on

      attr_reader :server_id

      def initialize(volt_app)
        @volt_app = volt_app

        if Volt::DataStore.fetch.connected?
          # Generate a guid
          @server_id = SecureRandom.uuid
          # The PeerConnection's to peers
          @peer_connections = {}
          # The server id's for each peer we're connected to
          @peer_server_ids = {}

          setup_peer_server
          start_tracker

          @peer_connection_threads = []

          @connect_thread = Thread.new do
            connect_to_peers
          end
        else
          Volt.logger.error('Unable to connect to the database.  Currently Volt requires running mongodb for a few things to work.  Volt will still run, but the message bus requires a database connection to setup connections between nodes, so the message bus has been disabled.  Also, the store collection can not be used without a database.  This means updates will not be propagated between instances (server, console, runners, etc...)')
        end
      end

      # The peer server maintains a socket other instances can connect to.
      def setup_peer_server
        @peer_server = PeerServer.new(self)
      end

      # The tracker updates the socket ip's and port and a timestamp into the
      # database every minute.  If the timestamp is more than 2 minutes old,
      # an instance is marked as "dead" and removed.
      def start_tracker
        @server_tracker = ServerTracker.new(@volt_app, @server_id, @peer_server.port)

        # Do the initial registration, and wait until its done before connecting
        # to peers.
        @server_tracker.register()
      end

      def publish(channel, message)
        full_msg = "#{channel}|#{message}"
        @peer_connections.keys.each do |peer|
          begin
            # Queue message on each peer
            peer.publish(full_msg)
          rescue IOError => e
            # Connection to peer lost
            Volt.logger.warn("Message bus connection to peer lost: #{e}")
          end
        end
      end

      # Return an array of peer records.
      def peers
        instances = @volt_app.store._active_volt_instances

        instances.where(server_id: {'$ne' => @server_id}).all.sync
      end

      def connect_to_peers
        peers.each do |peer|
          # Start connecting to all at the same time.  Since most will connect or
          # timeout, this is the desired behaviour.
          # sometimes we get nil peers for some reason
          if peer
            peer_connection = PeerConnection.new(nil, peer._ips, peer._port, self, false, peer._server_id)
            add_peer_connection(peer_connection)
          end
        end
      end

      # Blocks until all peers have connected or timed out.
      def disconnect!
        # Wait for disconnect on each
        @peer_connections.keys.each(&:disconnect!)
      end

      def add_peer_connection(peer_connection)
        @peer_connections[peer_connection] = true
        @peer_server_ids[peer_connection.peer_server_id] = true
      end

      def remove_peer_connection(peer_connection)
        @peer_connections.delete(peer_connection)
        @peer_server_ids.delete(peer_connection.peer_server_id)
      end

      # Called when a message comes in
      def handle_message(message)
        channel_name, message = message.split('|', 2)
        trigger!(channel_name, message)
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
              peer.disconnect!

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
        peer_table = @volt_app.store.active_volt_instances
        peer = peer_table.where(server_id: peer_server_id).first.sync
        if peer
          # Found the peer, retry if it has reported in in the last 2
          # minutes.
          if peer._time > (Time.now.to_i - DEAD_TIME)
            # Peer reported in less than 2 minutes ago
            return true
          else
            # Delete the entry
            peer.destroy
          end
        end

        false
      end

    end
  end
end