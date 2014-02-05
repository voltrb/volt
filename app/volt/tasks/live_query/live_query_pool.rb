require_relative 'live_query'

class LiveQueryPool
  def initialize(data_store)
    @pool = {}
    @data_store = data_store
  end
  
  # Called from a live query to remove its self from the pool
  def remove(live_query)
    # Remove the query from the collection
    if @pool[collection]
      @pool.delete(live_query.query)
    end
    
    # Delete the collection if its not in use anymore either.
    if @pool[collection] && @pool[collection].size == 0
      @pool.delete(live_query.collection)
    end
  end
  
  # Finds the live query if it has already been created
  def lookup_live_query(collection, query)
    query = normalize_query(query)
  
    stored_collection = @pool[collection]
  
    if stored_collection
      stored_query = stored_collection[query]
    
      return stored_query if stored_query
    end
  
    return create_live_query(collection, query)
  end
  
  def updated_collection(collection, skip_channel)
    if @pool[collection]
      @pool[collection].each_pair do |query,live_query|
        live_query.run(skip_channel)
      end
    end
  end
  
  private
    # Creates the live query if it doesn't exist, and stores it so it
    # can be found later.
    # TODO: make threadsafe
    def create_live_query(collection, query)
      # If not already setup, create a new one for this collection/query
      new_live_query = LiveQuery.new(self, @data_store, collection, query)
    
      @pool[collection] ||= {}
      @pool[collection][query] = new_live_query
    
      return new_live_query
    end
  
    def normalize_query(query)
      # TODO: add something to sort query properties so the queries are
      # always compared the same.
      return query
    end
end