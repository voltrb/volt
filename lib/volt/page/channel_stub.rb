# Acts the same as the Channel class on the front-end, but calls
# directly instead of using sockjs.

require 'volt/tasks/dispatcher'
require 'volt/reactive/eventable'

# Behaves the same as the Channel class, only the Channel class uses
# sockjs to pass messages to the backend.  ChannelStub, simply passes
# them directly to SocketConnectionHandlerStub.
class ChannelStub
  include Eventable

  attr_reader :state, :error, :reconnect_interval

  def initiailze
    @state = :connected
  end

  def opened
    trigger!('open')
    trigger!('changed')
  end

  def message_received(*message)
    trigger!('message', *message)
  end

  def send_message(message)
    SocketConnectionHandlerStub.new(self).process_message(message)
  end

  def close!
    raise "close! should not be called on the backend channel"
  end
end
