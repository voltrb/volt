# Tracks a channel and a query on a collection.  Alerts 
# the listener when the data in the query changes.
class LiveQuery  
  def initialize(collection, query)
    @collection = collection
    @query = query
  end
  
end