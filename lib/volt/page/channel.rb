# The channel is the connection between the front end and the backend.

require 'volt/reactive/events'
require 'json'

class Channel
  include ReactiveTags
  
  attr_reader :status, :error, :reconnect_interval
  
  def initialize
    @socket = nil
    @status = :opening
    @connected = false
    @error = nil
    @retry_count = 0
    @queue = []
    
    connect!
  end
  
  def connected?
    @connected
  end
  
  def retry_count
    @retry_count
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
    @status = :open
    @connected = true
    @reconnect_interval = nil
    @retry_count = 0
    @queue.each do |message|
      send_message(message)
    end
    
    trigger!('open')
    trigger!('changed')
  end

  def closed(error)
    @status = :closed
    @connected = false
    @error = `error.reason`
    
    trigger!('closed')
    trigger!('changed')
    
    reconnect!
  end
  
  def reconnect!
    @status = :reconnecting
    @reconnect_interval ||= 0
    @reconnect_interval += (2000 + rand(5000))
    @retry_count += 1
    
    # Trigger changed for reconnect interval
    trigger!('changed')
    
    interval = @reconnect_interval
    
    %x{
      setTimeout(function() {
        self['$connect!']();
      }, interval);
    }
  end
  
  def message_received(message)
    message = JSON.parse(message)
    trigger!('message', nil, *message)
  end
  
  tag_method(:send_message) do
    destructive!
  end
  def send_message(message)
    if @status != :open
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
    @status = :closed
    %x{
      this.socket.close();
    }
  end
end