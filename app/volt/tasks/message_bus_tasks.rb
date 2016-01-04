class MessageBusTasks < Volt::Task
  def publish(channel, message)
    Volt.current_app.message_bus.publish(channel, message)
    return true
  end
end