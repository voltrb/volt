require 'json'
require 'sockjs/session'
require 'volt/tasks/dispatcher'

class ChannelHandler < SockJS::Session
  # Create one instance of the dispatcher
  @@dispatcher = Dispatcher.new
  
  def self.message_all(message)
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
    # self.class.message_all(message)
    # Messages are json and wrapped in an array
    message = JSON.parse(message).first
    
    @@dispatcher.dispatch(message)
  end
  
  def closed    
    # Remove ourself from the available channels
    @@channels.delete(self)
  end

end