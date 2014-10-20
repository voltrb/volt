module Volt
  class SocketConnectionHandlerStub
    def self.dispatcher=(val)
      @@dispatcher = val
    end

    def self.dispatcher
      @@dispatcher
    end

    def initialize(channel_stub)
      @channel_stub = channel_stub
    end

    # Sends a message to all, optionally skipping a users channel
    def self.send_message_all(skip_channel = nil, *args)
      # Stub
    end

    def process_message(message)
      @@dispatcher.dispatch(self, message)
    end

    def send_message(*args)
      @channel_stub.message_received(*args)
    end
  end
end
