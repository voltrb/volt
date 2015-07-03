# Volt supports the concept of a message bus, a bus provides a pub/sub interface
# to any other volt instance (server, console, runner, etc..) inside a volt
# cluster.  Volt ships with a PeerToPeer message bus out of the box, but you
# can create or use other message bus's.
#
# MessageBus instances inherit from MessageBus::BaseMessageBus and provide
# two methods 'publish' and 'subscribe'.  They should be inside of
# Volt::MessageBus.
#
# publish should take a channel name and a message and deliver the message to
# any subscried listeners.
#
# subscribe should take a channel name and a block.  It should yield a message
# to the block if a message is published to the channel.
#
# The implementation details of the pub/sub connection are left to the
# implemntation.  If the user needs to configure server addresses, Volt.config
# is the prefered location, so it can be configured from config/app.rb
#
# MessageBus's should process their messages in their own thread. (And
# optionally may use a thread pool.)
#
# You can use lib/volt/server/message_bus/message_encoder.rb for encoding and
# encryption if needed.
#
# See lib/volt/server/message_bus/peer_to_peer.rb for details on volt's built-in
# message bus implementation.
#
# NOTE: in the future, we plan to add support for round robbin message receiving
# and other patterns.

module Volt
  module MessageBus
    class BaseMessageBus
      # MessagesBus's should take an instance of a Volt::App
      def initialize(volt_app)
        raise "Not implemented"
      end

      # Subscribe should return an object that you can call .remove on to stop
      # the subscription.
      def subscribe(channel_name, &block)
        raise "Not implemented"
      end

      # publish should push out to all subscribed within the volt cluster.
      def publish(channel_name, message)
        raise "Not implemented"
      end

      # waits for all messages to be flushed and closes connections
      def disconnect!
        raise "Not implemented"
      end
    end
  end
end