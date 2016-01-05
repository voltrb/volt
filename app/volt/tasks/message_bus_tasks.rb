class MessageBusTasks < Volt::Task
  require 'securerandom'

  # Publishes a message in the message bus
  def publish(channel, message)
    Volt.current_app.message_bus.publish(channel, message)
    return true
  end

  # Subscribe to specific events. Returns a listener_id, useful for unsubscribing
  def subscribe(*events)
    listener_id = generate_listener_id
    @@subscriptions ||= {}
    @@subscriptions[listener_id] = []

    events.each do |event|
      @@subscriptions[listener_id] << Volt.current_app.message_bus.on(event) do |msg|
        inform_subscriber(event, msg)
      end
    end

    return listener_id
  end

  # Removes a subscription, needs the listener_id (see #subscribe for more info)
  def remove(listener_id)
    if @@subscriptions && @@subscriptions[listener_id]
      @@subscriptions[listener_id].each &:remove
    end

    return listener_id
  end



  # todo: react on disconnect / connect
  # todo: authentication / authorization layer
  # todo: authenticate publishing and subscribing
  # todo: reauthenticate publish/subscribe on each message
  # todo: does publishing also fire the event locally?

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