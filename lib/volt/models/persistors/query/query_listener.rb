# The query listener is what gets notified on the backend when the results from
# a query have changed.  It then will make the necessary changes to any ArrayStore's
# to get them to display the new data.
class QueryListener
  def initialize(query_listener_pool, tasks, collection, query)
    @query_listener_pool = query_listener_pool
    @tasks = tasks
    @stores = []
    
    @collection = collection
    @query = query
    
    @listening = false
  end
  
  def add_listener
    @listening = true
    @tasks.call('QueryTasks', 'add_listener', @collection, @query)
  end
  
  def add_store(store)
    puts "ADD STORE: #{store.inspect} - to #{self.inspect}"
    @stores << store
    
    add_listener unless @listening
  end
  
  def remove_store(store)
    @stores.delete(store)
    
    # When there are no stores left, remove the query listener from
    # the pool, it can get created again later.
    if @stores.size == 0
      @query_listener_pool.remove(@collection, @query)
      
      # Stop listening
      if @listening
        @listening = false
        @tasks.call('QueryTasks', 'remove_listener', @collection, @query)        
      end
    end
  end
  
  def added(index, data)
    @stores.each do |store|
      store.add(index, data)
    end
    puts "Added: #{index} - #{data.inspect}"
  end
  
  def removed(ids)
    @stores.each do |store|
      store.remove(ids)
    end
  end
  
  def changed(model_id, data)
    $loading_models = true
    puts "From Backend: UPDATE: #{model_id} with #{data.inspect}"
    Persistors::ModelStore.changed(model_id, data)
    $loading_models = false
  end
end