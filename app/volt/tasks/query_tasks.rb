class QueryTasks
  @live_queries = {}
  
  # The dispatcher passes its self in
  def initialize(channel, dispatcher)
    @channel = channel
    @dispatcher = dispatcher
  end
  
  # Lookup to see if this query has been setup before.  It is has,
  # return the previous one, if not, create a new one.
  def lookup_live_query(collection, query)
    stored_collection = @live_queries[collection]
    
    if stored_collection
      stored_query = stored_collection[query]
      
      return stored_query if stored_query
    end
      
    return LiveQuery.new(collection, query)
  end
  
  def add_listener(collection, query)
    query = normalize_query(query)
    
    live_query = lookup_live_query(collection, query)
    
    @live_queries[collection] ||= {}
    @live_queries[collection][query] = live_query
  end
  
  
  # Normalizes a query so we don't end up creating more than needed
  # live queries.
  def normalize_query(query)
    # TODO: Add normalizer
    return query
  end
end