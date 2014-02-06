# The query listener is what gets notified on the backend when the results from
# a query have changed.  It then will make the necessary changes to any ArrayStore's
# to get them to display the new data.
class QueryListener
  def initialize(query_listener_pool, collection, query)
    @query_listener_pool = query_listener_pool
    @stores = []
    
    @collection = collection
    @query = query
    
    @listening = false
  end
  
  def add_listener
    @listening = true
    $page.tasks.call('QueryTasks', 'add_listener', @collection, @query)
  end
  
  def add_store(store)
    @stores << store
    
    add_listener unless @listening
  end
  
  def remove_store(store)
    @stores.delete(store)
    
    if @stores.size == 0
      @query_listener_pool.remove(@collection, @query)
    end
  end
  
  def added(index, data)
    @stores.each do |store|
      puts "Add to #{store.inspect}"
      store.add(index, data)
    end
    puts "Added: #{index} - #{data.inspect}"
  end
end