class ChannelTasks
  @@listeners = {}
  @@channel_listeners = {}
  
  # The dispatcher passes its self in
  def initialize(channel, dispatcher=nil)
    @channel = channel
  end
  
  def add_listener(channel_name)
    # Track every channel that is listening
    @@listeners[channel_name] ||= []
    @@listeners[channel_name] << @channel
    
    # Also keep track of which channel names a channel is listening
    # on so it can be removed if a channel is closed.
    @@channel_listeners[@channel] ||= {}
    @@channel_listeners[@channel][channel_name] = true
  end
  
  def remove_listener(channel_name)
    if @@listeners[channel_name]
      @@listeners[channel_name].delete(@channel)
      if @@channel_listeners[@channel]
        @@channel_listeners[@channel].delete(channel_name)
      end
    end
  end
  
  # Called when a channel is closed, removes its listeners from
  # all channels.
  def close!
    channel_names = @@channel_listeners.delete(@channel)
    
    if channel_names
      channel_names.each_pair do |channel_name,val|
        remove_listener(channel_name)
      end
    end
  end
  
  def self.send_message_to_channel(channel_name, message, skip_channel=nil)
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