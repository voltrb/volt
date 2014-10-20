require 'json'
require 'sockjs/session'
require File.join(File.dirname(__FILE__), '../../../app/volt/tasks/query_tasks')

module Volt
  class SocketConnectionHandler < SockJS::Session
    # Create one instance of the dispatcher

    def self.dispatcher=(val)
      @@dispatcher = val
    end

    def self.dispatcher
      @@dispatcher
    end

    # Sends a message to all, optionally skipping a users channel
    def self.send_message_all(skip_channel = nil, *args)
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

      @@dispatcher.dispatch(self, message)
    end

    def send_message(*args)
      str = JSON.dump([*args])

      begin
        send(str)
      rescue MetaState::WrongStateError => e
        puts "Tried to send to closed connection: #{e.inspect}"

        # Mark this channel as closed
        closed
      end
    end

    def closed
      # Remove ourself from the available channels
      @@channels.delete(self)

      QueryTasks.new(self).close!
    end

    def inspect
      "<#{self.class}:#{object_id}>"
    end
  end
end
