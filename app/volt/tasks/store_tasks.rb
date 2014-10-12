require 'mongo'

class StoreTasks < TaskHandler
  def initialize(channel=nil, dispatcher=nil)
    @channel = channel
    @dispatcher = dispatcher
  end

  def db
    @@db ||= Volt::DataStore.fetch
  end

  def model_values_and_errors(collection, data)
    model_name = collection.singularize.camelize

    # TODO: Security check to make sure we have a valid model
    # and don't load classes we shouldn't
    begin
      model_class = Object.send(:const_get, model_name)
    rescue NameError => e
      model_class = nil
    end

    if model_class
      model = model_class.new(data)
      return model.to_h, model.errors
    end

    return data, {}
  end

  def save(collection, data)
    puts "SAVE: #{data.inspect}"
    data = data.symbolize_keys
    values, errors = model_values_and_errors(collection, data)

    if errors.size == 0
      # id = BSON::ObjectId(values[:_id])
      id = values[:_id]

      # Try to create
      # TODO: Seems mongo is dumb and doesn't let you upsert with custom id's
      begin
        # values['_id'] = BSON::ObjectId('_id') if values['_id']
        puts "VALUES: #{values.inspect}"
        db[collection].insert(values)
      rescue Mongo::OperationFailure => error
        # Really mongo client?
        if error.message[/^11000[:]/]
          # Update because the id already exists
          update_values = values.dup
          update_values.delete(:_id)
          db[collection].update({:_id => id}, update_values)
        else
          return {:error => error.message}
        end
      end

      QueryTasks.live_query_pool.updated_collection(collection, @channel)
      return {}
    else
      return errors
    end
  end

  def delete(collection, id)
    db[collection].remove('_id' => id)

    QueryTasks.live_query_pool.updated_collection(collection, @channel)
  end
end
