module Volt
  # The query listener is what gets notified from the backend when the results from
  # a query have changed.  It then will make the necessary changes to any ArrayStore's
  # to get them to display the new data.
  class QueryListener
    attr_reader :listening

    def initialize(query_listener_pool, tasks, collection, query)
      @query_listener_pool = query_listener_pool
      @tasks               = tasks
      @stores              = []

      @collection = collection
      @query      = query
      @data       = []

      @listening = false
    end

    def add_listener
      @listening = true

      # Call the backend and add the listner
      QueryTasks.add_listener(@collection, @query).then do |ret|
        results, errors = ret

        # Store the data
        @data = results

        # When the initial data comes back, add it into the stores.
        @stores.dup.each do |store|
          # Clear if there are existing items
          Volt.run_in_mode(:no_model_promises) do
            store.model.clear if store.model.size > 0
          end

          if results.is_a?(Array)
            results.each_with_index do |data, index|
              store.add(index, data)
            end

            store.model.change_state_to(:loaded_state, :loaded)
          else
            store.resolve_value(results)
          end

          # if Volt.server?
          #   store.model.change_state_to(:loaded_state, :dirty)
          # end
        end
      end.fail do |err|
        # TODO: need to make it so we can re-raise out of this promise
        msg = "Error adding listener: #{err.inspect}"
        msg += "\n#{err.backtrace.join("\n")}" if err.respond_to?(:backtrace)
        Volt.logger.error(msg)

        # If we get back that the user signature is wrong, log the user out.
        if err.start_with?('VoltUserError:')
          # Delete the invalid cookie
          Volt.current_app.cookies.delete(:user_id)
        end

        fail err
      end
    end

    def add_store(store, &block)
      @stores << store

      if @listening
        # We are already listening and have this model somewhere else,
        # copy the data from the existing model.
        store.model.clear

        first_store = @stores.first

        if (resolved_value = first_store.resolved_value)
          store.resolve_value(resolved_value)
        else
          # Get an existing store to copy data from
          first_store_model = first_store.model
          first_store_model.each_with_index do |item, index|
            store.add(index, item.to_h)
          end

          store.model.change_state_to(:loaded_state, first_store_model.loaded_state)
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
          QueryTasks.remove_listener(@collection, @query)
        end
      end
    end

    def updated(diff)
      diff.each do |op|
        operation, arg1, arg2 = op

        case operation
        when 'i'
          # insert
          inserted(arg1, arg2)
        when 'r'
          # remove
          removed([arg1])
        when 'c'
          # changed
          changed(arg1, arg2)
        when 'm'
          # move
        when 'u'
          # single value, update it
          update(arg1)
        end
      end
    end

    def inserted(index, data)
      @stores.each do |store|
        store.add(index, data)
      end
    end

    def removed(ids)
      @stores.each do |store|
        store.remove(ids)
      end
    end

    def update(data)
      @stores.each do |store|
        store.resolve_value(data)
      end
    end

    def changed(model_id, data)
      puts "CH: #{model_id.inspect} - #{data.inspect}"
      $loading_models = true
      Persistors::ModelStore.changed(model_id, data)
      $loading_models = false
    end
  end
end
