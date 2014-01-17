class ChannelTasks
  @listeners = {}
  
  def initialize(channel, dispatcher)
    @channel = channel
    @dispatcher = dispatcher
  end
  
  def add_listener(channel_name)
    puts "REGISTER: #{channel_name}"
    @listeners[channel_name] ||= []
    @listeners[channel_name] << @channel
  end
  
  def remove_listener(channel_name)
    puts "UNREGISTER: #{channel_name}"
    if @listeners[channel_name]
      @listeners[channel_name].delete(@channel)
    end
  end
end