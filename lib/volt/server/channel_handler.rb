require 'json'
require 'sockjs/session'

class ChannelHandler < SockJS::Session
  def self.message_all
    @@channels.each do |channel|
      channel.send(message)
    end
    
  end
  
  def initialize(session, *args)
    @session = session

    @@channels ||= []
    @@channels << self
    
    super
  end
  
  def process_message(message)
    puts "Process: #{message}"
    self.class.message_all(message)
  end
  
  def closed    
    # Remove ourself from the available channels
    @@channels.delete(self)
  end

end