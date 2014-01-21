require 'json'
require 'sockjs/session'

class ChannelHandler < SockJS::Session
  # Create one instance of the dispatcher
  
  def self.dispatcher=(val)
    @@dispatcher = val
  end
  
  def self.dispatcher
    @@dispatcher
  end
  
  # Sends a message to all, optionally skipping a users channel
  def self.send_message_all(skip_channel=nil, *args)
    @@channels.each do |channel|
      if skip_channel && channel == skip_channel
        next
      end
      channel.send_message(*args)
    end
    
  end
  
  def initialize(session, *args)
    @session = session

    @@channels ||= []
    @@channels << self
    
    super
  end
  
  def process_message(message)
    # self.class.message_all(message)
    # Messages are json and wrapped in an array
    message = JSON.parse(message).first
    
    puts "GOT: #{message.inspect}"
    @@dispatcher.dispatch(self, message)
  end
  
  def send_message(*args)
    str = JSON.dump([*args])
    
    send(str)
  end
  
  def closed    
    # Remove ourself from the available channels
    @@channels.delete(self)
  end

end