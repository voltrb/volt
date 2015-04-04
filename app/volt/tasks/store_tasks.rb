require 'mongo'
require 'volt/models'

class StoreTasks < Volt::TaskHandler
  def initialize(channel = nil, dispatcher = nil)
    @channel = channel
    @dispatcher = dispatcher
  end

  def db
    @@db ||= Volt::DataStore.fetch
  end

  def load_model(collection, path, data)
    model_name = collection.singularize.camelize

    # Fetch the model
    collection = store.send(:"_#{path[-2]}")

    # See if the model has already been made
    collection.find(_id: data[:_id]).fetch_first do |model|
      # Otherwise assign to the collection
      model ||= collection

      # Create a buffer
      buffer = model.buffer

      # Assign the changed data to the buffer
      buffer.assign_attributes(data, false, true)

      buffer
    end
  end

  def save(collection, path, data)
    data = data.symbolize_keys
    promise = nil
    Volt::Model.no_validate do
      promise = load_model(collection, path, data)
    end

    # On the backend, the promise is resolved before its returned, so we can
    # return from within it.
    #
    # Pass the channel as a thread-local so that we don't update the client
    # who sent the update.
    #
    # return another promise
    return promise.then do |model|
      Thread.current['in_channel'] = @channel
      save_promise = model.save!.then do |result|

        next nil
      end

      Thread.current['in_channel'] = nil

      next save_promise
    end
  end

  def delete(collection, id)
    # Load the model, then call .destroy on it
    store.send(:"_#{collection}").where(_id: id).fetch_first do |model|
      if model
        if model.can_delete?
          db[collection].remove('_id' => id)
        else
          raise "Permissions did not allow #{collection} #{id} to be deleted."
        end

        QueryTasks.live_query_pool.updated_collection(collection, @channel)
      else
        raise "Could not find #{id} in #{collection}"
      end
    end
  end
end
