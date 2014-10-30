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
    puts "Load Model: #{path.inspect}"
    model_name = collection.singularize.camelize

    # TODO: Security check to make sure we have a valid model
    # and don't load classes we shouldn't
    begin
      model_class = Object.send(:const_get, model_name)
    rescue NameError => e
      model_class = Volt::Model
    end

    # Load the model, use the Store persistor and set the path
    model = model_class.new({}, persistor: Volt::Persistors::StoreFactory.new(nil), path: path)
    model.persistor.change_state_to(:loaded)

    # Create a buffer
    buffer = model.buffer

    # Assign the data
    buffer.attributes = data

    return buffer
  end

  def save(collection, path, data)
    data = data.symbolize_keys
    model = nil
    Volt::Model.nosave do
      model = load_model(collection, path, data)
    end

    # On the backend, the promise is resolved before its returned, so we can
    # return from within it.
    #
    # Pass the channel as a thread-local so that we don't update the client
    # who sent the update.
    Thread.current['in_channel'] = @channel
    promise = model.save!.then do |result|
      return nil
    end

    Thread.current['in_channel'] = nil

    return promise
  end

  def delete(collection, id)
    db[collection].remove('_id' => id)

    QueryTasks.live_query_pool.updated_collection(collection, @channel)
  end
end
