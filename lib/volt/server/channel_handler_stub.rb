class ChannelHandlerStub
  def self.dispatcher=(val)
    @@dispatcher = val
  end

  def self.dispatcher
    @@dispatcher
  end
  
  def initialize(channel_stub)
    puts "INIT WITH : #{channel_stub.inspect}"
    @channel_stub = channel_stub
  end

  # Sends a message to all, optionally skipping a users channel
  def self.send_message_all(skip_channel=nil, *args)
    # Stub
  end

  def process_message(message)
    puts "GOT: #{message.inspect}"
    @@dispatcher.dispatch(self, message)
  end

  def send_message(*args)
    puts "SEND MSG: #{args.inspect}"
    @channel_stub.message_received(*args)
  end
end