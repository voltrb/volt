require_relative 'live_query/data_store'
require_relative 'live_query/live_query_pool'

class QueryTasks
  @@live_query_pool = LiveQueryPool.new(DataStore.new)
  @@channel_live_queries = {}
  
  def self.live_query_pool
    @@live_query_pool
  end
    
  # The dispatcher passes its self in
  def initialize(channel, dispatcher=nil)
    @channel = channel
    @dispatcher = dispatcher
  end
  
  def add_listener(collection, query)
    puts "Add listener for #{collection} - #{query.inspect}"
    live_query = @@live_query_pool.lookup(collection, query)
    track_channel_in_live_query(live_query)
    
    live_query.add_channel(@channel)
    
    live_query.notify_initial_data!(@channel)
    puts "Update for new"
  end
  
  # Remove a listening channel, the LiveQuery will automatically remove 
  # itsself from the pool when there are no channels.
  def remove_listener(collection, query)
    puts "Remove Channel"
    live_query = @@live_query_pool.lookup(collection, query)
    live_query.remove_channel(@channel)
  end
  
  
  # Removes a channel from all associated live queries
  def close!
    live_queries = @@channel_live_queries[@channel]
    
    if live_queries
      live_queries.each do |live_query|
        live_query.remove_channel(@channel)
      end
    end
    
    @@channel_live_queries.delete(@channel)
  end
  
  private
    # Tracks that this channel will be notified from the live query.
    def track_channel_in_live_query(live_query)
      @@channel_live_queries[@channel] ||= []
      @@channel_live_queries[@channel] << live_query
    end


end