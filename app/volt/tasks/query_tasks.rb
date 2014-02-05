require_relative 'live_query_pool'

class QueryTasks
  @@live_query_pool = LiveQueryPool.new
  @@channel_live_queries = {}
  
  def self.live_query_pool
    @@live_query_pool
  end
    
  # The dispatcher passes its self in
  def initialize(channel, dispatcher)
    @channel = channel
    @dispatcher = dispatcher
  end
  
  
  def add_listener(collection, query)
    puts "Add listener for #{collection} - #{query.inspect}"
    live_query = @@live_query_pool.lookup_live_query(collection, query)
    track_channel_in_live_query(live_query)
    
    live_query.add_channel(@channel)
    
    live_query.update!(nil, @channel)
    puts "Update for new"
  end
  
  private
    # Tracks that this channel will be notified from the live query.
    def track_channel_in_live_query(live_query)
      @@channel_live_queries[@channel] ||= []
      @@channel_live_queries[@channel] << live_query
    end
    
    # Removes a channel from all associated live queries
    def close!
      live_queries = @@channel_live_queries[channel]
      
      if live_queries
        live_queries.each do |live_query|
          live_query.remove_channel(@channel)
        end
      end
      
      @@channel_live_queries.delete(channel)
    end

end