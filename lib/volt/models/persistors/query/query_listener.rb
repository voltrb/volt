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
    @tasks.call('QueryTasks', 'add_listener', @collection, @query) do |results, errors|
      # puts "Query Tasks: #{results.inspect} - #{@stores.inspect} - #{self.inspect}"
      # When the initial data comes back, add it into the stores.
      @stores.each do |store|
        # Clear if there are existing items
        store.model.clear if store.model.size > 0

        results.each do |index, data|
          # puts "ADD: #{index} - #{data.inspect}"
          store.add(index, data)
        end

        store.change_state_to(:loaded)
      end
    end
  end

  def add_store(store, &block)
    @stores << store

    if @listening
      # We are already listening and have this model somewhere else,
      # copy the data from the existing model.
      store.model.clear
      @stores.first.model.each_with_index do |item, index|
        store.add(index, item)
      end
    else
      # First time we've added a store, setup the listener and get
      # the initial data.
      add_listener
    end
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
  end

  def removed(ids)
    @stores.each do |store|
      store.remove(ids)
    end
  end

  def changed(model_id, data)
    $loading_models = true
    Persistors::ModelStore.changed(model_id, data)
    $loading_models = false
  end
end
