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

    # TODO: Security check to make sure we have a valid model
    # and don't load classes we shouldn't
    begin
      model_class = Object.send(:const_get, model_name)
    rescue NameError => e
      model_class = Volt::Model
    end

    if model_class
      # Load the model, use the Store persistor and set the path
      model = model_class.new(data, persistor: Volt::Persistors::StoreFactory.new(nil), path: path)
      return model
    end

    return nil
  end

  def save(collection, path, data)
    data = data.symbolize_keys
    model = load_model(collection, path, data)

    errors = model.errors

    if model.errors.size == 0

      # On the backend, the promise is resolved before its returned, so we can
      # return from within it.
      #
      # Pass the channel as a thread-local so that we don't update the client
      # who sent the update.
      Thread.current['in_channel'] = @channel
      model.persistor.changed do |errors|
        Thread.current['in_channel'] = nil

        return errors
      end
    else
      return errors
    end
  end

  def delete(collection, id)
    db[collection].remove('_id' => id)

    QueryTasks.live_query_pool.updated_collection(collection, @channel)
  end
end
