# Acts the same as the Channel class on the front-end, but calls
# directly instead of using sockjs.

require 'volt/reactive/events'
require 'volt/tasks/dispatcher'

# Behaves the same as the Channel class, only the Channel class uses
# sockjs to pass messages to the backend.  ChannelStub, simply passes
# them directly to ChannelHandlerStub.
class ChannelStub
  include ReactiveTags

  attr_reader :state, :error, :reconnect_interval
  
  def initiailze
    @state = :connected
  end
  
  def opened
    trigger!('open')
    trigger!('changed')
  end
  
  def message_received(*message)
    trigger!('message', nil, *message)
  end
  
  tag_method(:send_message) do
    destructive!
  end
  def send_message(message)
    ChannelHandlerStub.new(self).process_message(message)
  end
  
  def close!
    raise "close! should not be called on the backend channel"
  end
end