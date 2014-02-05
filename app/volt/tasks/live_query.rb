require_relative 'data_store'

# Tracks a channel and a query on a collection.  Alerts 
# the listener when the data in the query changes.
class LiveQuery
  attr_reader :current_ids
  
  def initialize(pool, collection, query)
    @pool = pool
    @collection = collection
    @query = query
    
    @channels = []
    @data_store = DataStore.new
    
    # Stores the list of id's currently associated with this query
    @current_ids = []
    @results = []
    
    run
  end
  
  # Runs the query, stores the results and updates the current_ids
  def run
    @results = @data_store.query(@collection, @query)
    
    @current_ids = @results.map {|r| r['_id'] }
    
    update!
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
  
  def update!(skip_channel=nil, only_channel=nil)
    if only_channel
      channels = [only_channel]
    else
      channels = @channels
    end
    
    channels.reject! {|c| c == skip_channel }
    
    channels.each do |channel|
      puts "PUSH: #{@results.inspect}"
      channel.send_message("updated", nil, @collection, @query, @results)
    end
  end
  
end