require 'volt/utils/ejson'
require File.join(File.dirname(__FILE__), '../../../app/volt/tasks/query_tasks')

module Volt
  class SocketConnectionHandler
    # Create one instance of the dispatcher

    # We track the connected user_id with the channel for use with permissions.
    # This may be changed as new listeners connect, which is fine.
    attr_accessor :user_id


    def initialize(session, *args)
      @session = session

      @@channels ||= []
      @@channels << self

      # Trigger a client connect event
      @@dispatcher.volt_app.trigger!("client_connect")

    end

    def update_user_id(user_id)
      if !@user_id && user_id
        # If there is currently no user id associated with this channel
        # and we get a new valid user_id, set it then trigger a
        # user_connect event
        @user_id = user_id
        @@dispatcher.volt_app.trigger!("user_connect", @user_id)
      elsif @user_id && !user_id
        # If there is currently a user id associated with this channel
        # and we get a nil user id, trigger a user_disconnect event then
        # set the id to nil
        @@dispatcher.volt_app.trigger!("user_disconnect", @user_id)
        @user_id = user_id
      else
        # Otherwise, lets just set the id (should never really run)
        @user_id = user_id
      end
    end

    def self.dispatcher=(val)
      @@dispatcher = val
    end

    def self.dispatcher
      defined?(@@dispatcher) ? @@dispatcher : nil
    end

    def self.channels
      @@channels
    end

    # Sends a message to all, optionally skipping a users channel
    def self.send_message_all(skip_channel = nil, *args)
      return unless defined?(@@channels)
      @@channels.each do |channel|
        next if skip_channel && channel == skip_channel
        channel.send_message(*args)
      end
    end

    def process_message(message)
      # Messages are json and wrapped in an array
      begin
        message = EJSON.parse(message).first
      rescue JSON::ParserError => e
        Volt.logger.error("Unable to process task request message: #{message.inspect}")
      end

      begin
        @@dispatcher.dispatch(self, message)
      rescue => e
        if defined?(DRb::DRbConnError) && e.is_a?(DRb::DRbConnError)
          # The child process was restarting, so drb failed to send
        else
          # re-raise the issue
          raise
        end
      end
    end

    # Used when the message is already encoded
    def send_string_message(str)
      send_raw_message(str)
    end

    def send_message(*args)
      # Encode as EJSON
      str = EJSON.stringify([*args])

      send_raw_message(str)
    end

    def send_raw_message(str)
      @session.send(str)

      if RUNNING_SERVER == 'thin'
        # This might seem strange, but it prevents a delay with outgoing
        # messages.
        # TODO: Figure out the cause of the issue and submit a fix upstream.
        EM.next_tick {}
      end
    end

    def closed
      unless @closed
        @closed = true
        # Remove ourself from the available channels
        @@channels.delete(self)

        begin
          @@dispatcher.close_channel(self)

          # Check for volt_app (@@dispatcher could be an ErrorDispatcher)
          if @@dispatcher.respond_to?(:volt_app)
            # Trigger a client disconnect event
            @@dispatcher.volt_app.trigger!("client_disconnect")

            # Trigger a user disconnect event even if the user hasn't logged out
            if @user_id
              @@dispatcher.volt_app.trigger!("user_disconnect", @user_id)
            end
          end

        rescue DRb::DRbConnError => e
        # ignore drb read of @@dispatcher error if child has closed
        end
      else
        Volt.logger.error("Socket Error: Connection already closed\n#{inspect}")
      end
    end

    def inspect
      "<#{self.class}:#{object_id}>"
    end
  end
end
