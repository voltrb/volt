require 'securerandom'

class MessageBusTasks < Volt::Task

  # Publishes a message in the message bus
  def publish(channel, message)
    # Trigger subscriptions in remote volt app (via the message bus)
    Volt.current_app.message_bus.publish(channel, message)

    # Trigger local subscriptions, of local volt app
    Volt.current_app.message_bus.trigger!(channel, message)
    return true
  end

  # Subscribe to specific events. Returns a listener_id, useful for unsubscribing
  def subscribe(*events)
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



  # todo: authentication / authorization layer
  # todo: authenticate publishing and subscribing
  # todo: reauthenticate publish/subscribe on each message

  private

  # informs subscriber about new message in channel
  def inform_subscriber(channel, msg)
    @channel.send_message('message_bus_event', channel, msg)
  end

  # Just returns a random listener_id
  def generate_listener_id
    SecureRandom.uuid
  end
end