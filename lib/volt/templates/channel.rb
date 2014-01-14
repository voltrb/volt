# The channel is the connection between the front end and the backend.

require 'volt/reactive/events'
require 'json'

class Channel
  include Events
  
  def initialize
    @socket = nil
    %x{
      this.socket = new SockJS('http://localhost:3000/channel');//, {reconnect: true});

      this.socket.onopen = function() {
        self['$trigger!']("open");
      };

      this.socket.onmessage = function(message) {
        console.log('received: ', message);
        self['$message_received'](message.data);
      };
    }
  end
  
  def message_received(message)
    message = JSON.parse(message)
    puts "Got #{message.inspect}"
    
    trigger!('message', message)
  end
  
  def send(message)
    # TODO: Temp: wrap message in an array, so we're sure its valid JSON
    message = JSON.dump([message])
    %x{
      //message = window.JSON.parse(message);
      console.log('send: ', message);
      this.socket.send(message);
    }
  end
  
  def close
    %x{
      this.socket.close();
    }
  end
end