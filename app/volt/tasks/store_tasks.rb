require 'volt/models'

class StoreTasks < Volt::Task
  def db
    @@db ||= Volt::DataStore.fetch
  end

  def load_model(collection, path, data)
    model_name = collection.singularize.camelize

    # Fetch the model
    collection = store.get(path[-2])

    # See if the model has already been made
    model_promise = collection.where(id: data[:id]).first

    return collection, model_promise
  end

  def save(collection, path, data)
    data = data.symbolize_keys
    model_promise = nil

    Volt.skip_permissions do
      Volt::Model.no_validate do
        collection, model_promise = load_model(collection, path, data)
      end
    end

    # On the backend, the promise is resolved before its returned, so we can
    # return from within it.
    #
    # Pass the channel as a thread-local so that we don't update the client
    # who sent the update.
    #
    # return another promise
    model_promise.then do |model|
      Thread.current['in_channel'] = @channel

      result = if model
        model.update(data)
      else
        collection.create(data)
      end

      save_promise = result.then do |result|
        next nil
      end.fail do |err|
        # An error object, convert to hash
        Promise.new.reject(err.to_h)
      end

      Thread.current['in_channel'] = nil

      next save_promise
    end
  end

  def delete(collection, id)
    # Load the model, then call .destroy on it
    query = nil

    Volt.skip_permissions do
      query = store.get(collection).where(id: id)
    end

    query.first.then do |model|
      if model
        if model.can_delete?
          db.delete(collection, 'id' => id)
        else
          fail "Permissions did not allow #{collection} #{id} to be deleted."
        end

        @volt_app.live_query_pool.updated_collection(collection, @channel)
      else
        fail "Could not find #{id} in #{collection}"
      end
    end
  end
end
