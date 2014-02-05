require_relative 'live_query'

class ChannelTasks
  @@listeners = {}
  @@channel_listeners = {}
  
  # The dispatcher passes its self in
  def initialize(channel, dispatcher)
    @channel = channel
    @dispatcher = dispatcher
  end
  
  def add_listener(collection, query)
    live_query = LiveQuery.new(@channel, collection, query)
    
    # Track every channel that is listening
    @@listeners[collection] ||= []
    @@listeners[collection] << live_query
    
    # Also keep track of which channel names a channel is listening
    # on so it can be removed if a channel is closed.
    @@channel_listeners[@channel] ||= {}
    @@channel_listeners[@channel][collection] = true
  end
  
  def remove_listener(collection, query)
    if @@listeners[collection]
      @@listeners[collection].delete(@channel)
      if @@channel_listeners[@channel]
        @@channel_listeners[@channel].delete(collection)
      end
    end
  end
  
  # Called when a channel is closed, removes its listeners from
  # all channels.
  def close!
    collections = @@channel_listeners.delete(@channel)
    
    if collections
      collections.each_pair do |collection,val|
        remove_listener(collection)
      end
    end
  end
  
  def self.send_message_to_channel(collection, message, skip_channel=nil)
    listeners = @@listeners[collection]
    
    if listeners
      listeners.each do |listener|
        # We might need to skip a channel if the update came in on this
        # channel.
        next if listener == skip_channel
        
        listener.send_message(*message)
      end
    end
  end
end