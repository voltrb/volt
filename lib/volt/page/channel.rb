# The channel is the connection between the front end and the backend.

require 'json'
require 'volt/reactive/reactive_accessors'
require 'volt/reactive/eventable'

module Volt
  class Channel
    include ReactiveAccessors
    include Eventable

    reactive_accessor :connected, :status, :error, :reconnect_interval, :retry_count, :reconnect_in

    def initialize
      @socket          = nil
      self.status      = :opening
      self.connected   = false
      self.error       = nil
      self.retry_count = 0
      @queue           = []

      connect!
    end

    def connected?
      connected
    end

    def connect!
      `
        this.socket = new SockJS('/channel');

        this.socket.onopen = function() {
          self.$opened();
        };

        this.socket.onmessage = function(message) {
          self['$message_received'](message.data);
        };

        this.socket.onclose = function(error) {
          self.$closed(error);
        };
      `
    end

    def opened
      self.status             = :open
      self.connected          = true
      self.reconnect_interval = nil
      self.retry_count        = 0
      @queue.each do |message|
        send_message(message)
      end
    end

    def closed(error)
      self.status    = :closed
      self.connected = false
      self.error     = `error.reason`

      reconnect!
    end

    def reconnect!
      self.status             = :reconnecting
      self.reconnect_interval ||= 0
      self.reconnect_interval += (1000 + rand(5000))
      self.retry_count        += 1

      interval = self.reconnect_interval

      self.reconnect_in = interval

      reconnect_tick
    end

    def message_received(message)
      message = JSON.parse(message)

      trigger!('message', *message)
    end

    def send_message(message)
      if status != :open
        @queue << message
      else
        # TODO: Temp: wrap message in an array, so we're sure its valid JSON
        message = JSON.dump([message])
        `
          this.socket.send(message);
        `
      end
    end

    def close!
      self.status = :closed
      `
        this.socket.close();
      `
    end

    private

    def reconnect_tick
      if reconnect_in >= 1000
        self.reconnect_in -= 1000
        `
        setTimeout(function() {
          self['$reconnect_tick']();
        }, 1000);
        `
      else
        connect!
      end
    end

  end
end
