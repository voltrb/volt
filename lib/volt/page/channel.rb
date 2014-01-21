# The channel is the connection between the front end and the backend.

require 'volt/reactive/events'
require 'json'

class Channel
  include Events
  
  def initialize
    @socket = nil
    @state = :opening
    @queue = []
    %x{
      this.socket = new SockJS('http://localhost:3000/channel');//, {reconnect: true});

      this.socket.onopen = function() {
        self.$open();
        self['$trigger!']("open");
      };

      this.socket.onmessage = function(message) {
        self['$message_received'](message.data);
      };
    }
  end
  
  def open
    @state = :open
    @queue.each do |message|
      send(message)
    end
  end
  
  def message_received(message)
    message = JSON.parse(message)
    puts "GOT: #{message.inspect}"
    trigger!('message', nil, *message)
  end
  
  def send(message)
    if @state != :open
      @queue << message
    else
      # TODO: Temp: wrap message in an array, so we're sure its valid JSON
      message = JSON.dump([message])
      %x{
        this.socket.send(message);
      }
    end
  end
  
  def close
    @state = :closed
    %x{
      this.socket.close();
    }
  end
end