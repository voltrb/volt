class ChannelTasks
  @@listeners = {}
  
  def initialize(channel, dispatcher)
    @channel = channel
    @dispatcher = dispatcher
  end
  
  def add_listener(channel_name)
    puts "REGISTER: #{channel_name}"
    @@listeners[channel_name] ||= []
    @@listeners[channel_name] << @channel
  end
  
  def remove_listener(channel_name)
    puts "UNREGISTER: #{channel_name}"
    if @@listeners[channel_name]
      @@listeners[channel_name].delete(@channel)
    end
  end
  
  def self.send_message_to_channel(channel_name, message, skip_channel)
    listeners = @@listeners[channel_name]
    
    if listeners
      listeners.each do |listener|
        # We might need to skip a channel if the update came in on this
        # channel.
        next if listener == skip_channel
        
        listener.send_message(*message)
      end
    end
  end
end