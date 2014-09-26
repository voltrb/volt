# The channel is the connection between the front end and the backend.

require 'json'
require 'volt/reactive/reactive_accessors'
require 'volt/reactive/eventable'

class Channel
  include ReactiveAccessors
  include Eventable

  reactive_accessor :connected, :status, :error, :reconnect_interval, :retry_count

  def initialize
    @socket = nil
    self.status = :opening
    self.connected = false
    self.error = nil
    self.retry_count = 0
    @queue = []

    connect!
  end

  def connected?
    self.connected
  end

  def connect!
    %x{
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
    }
  end

  def opened
    old_status = @status
    @status = :open
    @connected = true
    @reconnect_interval = nil
    @retry_count = 0
    @queue.each do |message|
      send_message(message)
    end
  end

  def closed(error)
    self.status = :closed
    self.connected = false
    self.error = `error.reason`

    reconnect!
  end

  def reconnect!
    self.status = :reconnecting
    self.reconnect_interval ||= 0
    self.reconnect_interval += (2000 + rand(5000))
    self.retry_count += 1

    interval = self.reconnect_interval

    %x{
      setTimeout(function() {
        self['$connect!']();
      }, interval);
    }
  end

  def message_received(message)
    message = JSON.parse(message)

    trigger!('message', *message)
  end

  def send_message(message)
    if self.status != :open
      @queue << message
    else
      # TODO: Temp: wrap message in an array, so we're sure its valid JSON
      message = JSON.dump([message])
      %x{
        this.socket.send(message);
      }
    end
  end

  def close!
    self.status = :closed
    %x{
      this.socket.close();
    }
  end
end
