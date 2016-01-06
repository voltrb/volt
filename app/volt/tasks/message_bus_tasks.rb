# Remote endpoint for publishing and subscribing to message bus
# Generally you have the power to publish or subscribe to any channel, even to volt internals, if you
# want to.
# Nevertheless, all channels are protected by an authorization layer, so publishing and subscribing
# from client is only possible if the specified user is allowed to. Per default, channel names starting
# with 'public:' are usable for everyone. If you want to restrict some channels / use the authorization
# layer, have a look at /server/message_bus/client_authorizer, where everything you need to know is
# explained very well.
# Volt uses channels starting with 'volt:' for internal stuff, so be aware of publishing / subscribing
# to these channels (although you could do!)

require 'securerandom'
require 'volt/server/message_bus/client_authorizer'

class MessageBusTasks < Volt::Task

  # Publishes a message in the message bus
  def publish(channel, message)
    fail "[MessageBus] Publishing into channel #{channel} not allowed" unless publishing_allowed? channel

    # Trigger subscriptions in remote volt app (via the message bus)
    Volt.current_app.message_bus.publish(channel, message)

    # Trigger local subscriptions, of local volt app
    Volt.current_app.message_bus.trigger!(channel, message)

    nil
  end

  # Subscribe to specific events. Returns a listener_id, useful for unsubscribing
  def subscribe(*events)
    fail "[MessageBus] Subscribing to channels #{events} not allowed" unless subscribing_allowed? *events

    listener_id = generate_listener_id
    @@subscriptions ||= {}
    @@subscriptions[listener_id] = []

    # Todo: Maybe do this in a custom thread?
    events.each do |event|
      @@subscriptions[listener_id] << Volt.current_app.message_bus.on(event) do |msg|
        inform_subscriber(event, msg)
      end
    end

    # Remove all registered listeners on client disconnect
    connection_listener = Volt.current_app.on('client_disconnect') do
      remove(listener_id)
      connection_listener.remove # to avoid endless listeners
    end

    # Todo: If a client reconnects, automatically reattach all subscriptions?!

    return listener_id
  end

  # Removes a subscription, needs the listener_id (see #subscribe for more info)
  def remove(listener_id)
    if @@subscriptions && @@subscriptions[listener_id]
      @@subscriptions[listener_id].each &:remove
      @@subscriptions[listener_id] = nil
    end

    return listener_id
  end


  # Checks if publishing to the given channels is allowed
  def publishing_allowed?(*channels)
    is_allowed? :publish, *channels
  end

  # Checks if subscribing to the given channels is allowed
  def subscribing_allowed?(*channels)
    is_allowed? :subscribe, *channels
  end

  # todo: enable usage in views

  private

  # informs subscriber about new message in channel
  def inform_subscriber(channel, msg)
    return unless subscribing_allowed? channel

    @channel.send_message('message_bus_event', channel, msg)
  end

  # Just returns a random listener_id
  def generate_listener_id
    SecureRandom.uuid
  end

  # [helper method] Checks if :subscribe or :publish is allowed in all channels
  def is_allowed?(method, *channels)
    channels.each do |channel|
      return false if Volt::MessageBus::ClientAuthorizer.authorized?(self, method, channel) != true
    end

    true
  end
end