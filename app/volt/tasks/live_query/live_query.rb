require_relative 'query_tracker'

# Tracks a channel and a query on a collection.  Alerts 
# the listener when the data in the query changes.
class LiveQuery
  attr_reader :current_ids, :collection, :query
  
  def initialize(pool, data_store, collection, query)
    @pool = pool
    @collection = collection
    @query = query
    
    @channels = []
    @data_store = data_store
    
    # Stores the list of id's currently associated with this query
    @current_ids = []
    @results = []
    
    @query_tracker = QueryTracker.new(self, @data_store)
    @query_tracker.run
  end
  
  
  def notify_removed(ids, skip_channel)
    notify!(skip_channel) do |channel|
      channel.send_message("removed", nil, @collection, @query, ids)
    end
  end
  
  def notify_added(id, index, data, skip_channel)
    notify!(skip_channel) do |channel|
      channel.send_message("added", nil, @collection, @query, id, data)
    end
  end
  
  def notify_moved(id, new_position, skip_channel)
    notify!(skip_channel) do |channel|
      channel.send_message("moved", nil, @collection, @query, id, new_position)
    end
  end
  
  def add_channel(channel)
    @channels << channel
  end
  
  def remove_channel(channel)
    @channels.delete(channel)
    
    if @channels.size == 0
      # remove this query, no one is listening anymore
      @pool.remove(self)
    end
  end
  
  def notify!(skip_channel=nil, only_channel=nil)
    if only_channel
      channels = [only_channel]
    else
      channels = @channels
    end
    
    channels.reject! {|c| c == skip_channel }
    
    channels.each do |channel|
      puts "PUSH: #{@results.inspect}"
      yield(channel)
      # channel.send_message("updated", nil, @collection, @query, @results)
    end
  end
  
end