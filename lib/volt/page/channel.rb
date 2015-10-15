# The channel is the connection between the front end and the backend.

require 'volt/utils/ejson'
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
      # The websocket url can be overridden by config.public.websocket_url
      socket_url = Volt.config.try(:public).try(:websocket_url) || begin
        "#{`document.location.host`}/socket"
      end

      if socket_url !~ /^wss?[:]\/\//
        if socket_url !~ /^[:]\/\//
          # Add :// to the front
          socket_url = "://#{socket_url}"
        end

        ws_proto = (`document.location.protocol` == 'https:') ? 'wss' : 'ws'

        # Add wss? to the front
        socket_url = "#{ws_proto}#{socket_url}"
      end

      `
        this.socket = new WebSocket(socket_url);

        this.socket.onopen = function () {
          self.$opened();
        };

        // Log errors
        this.socket.onerror = function (error) {
          console.log('WebSocket Error ', error);
        };

        // Log messages from the server
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

      # Trigger a connect event
      trigger!('connect')
    end

    def closed(error)
      self.status    = :closed
      self.connected = false
      self.error     = `error.reason`

      # Trigger a disconnect event
      trigger!('disconnect')

      reconnect!
    end

    def reconnect!
      self.status             = :reconnecting
      self.reconnect_interval ||= 0
      self.reconnect_interval += (1000 + rand(5000))
      self.retry_count += 1

      interval = self.reconnect_interval

      self.reconnect_in = interval

      reconnect_tick
    end

    def message_received(message)
      message = EJSON.parse(message)

      trigger!('message', *message)
    end

    def send_message(message)
      if status != :open
        @queue << message
      else
        # TODO: Temp: wrap message in an array, so we're sure its valid JSON
        message = EJSON.stringify([message])
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
