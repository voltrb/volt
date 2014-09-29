require 'mongo'
require 'query_tasks'

class StoreTasks
  def initialize(channel=nil, dispatcher=nil)
    @@mongo_db ||= Mongo::MongoClient.new(
      Volt.config.db[:host], Volt.config.db[:port]
    )
    @@db ||= @@mongo_db.db(Volt.config.db[:name])

    @channel = channel
    @dispatcher = dispatcher
  end

  def db
    @@db
  end

  def model_errors(collection, data)
    model_name = collection[1..-1].singularize.camelize

    # TODO: Security check to make sure we have a valid model
    begin
      model_class = Object.send(:const_get, model_name)
    rescue NameError => e
      model_class = nil
    end

    if model_class
      return model_class.new(data).errors
    end

    return {}
  end

  def save(collection, data)
    data = data.symbolize_keys

    errors = model_errors(collection, data)

    if errors.size == 0
      # id = BSON::ObjectId(data[:_id])
      id = data[:_id]

      # Try to create
      # TODO: Seems mongo is dumb and doesn't let you upsert with custom id's
      begin
        # data['_id'] = BSON::ObjectId('_id') if data['_id']
        @@db[collection].insert(data)
      rescue Mongo::OperationFailure => error
        # Really mongo client?
        if error.message[/^11000[:]/]
          # Update because the id already exists
          update_data = data.dup
          update_data.delete(:_id)
          @@db[collection].update({:_id => id}, update_data)
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
    @@db[collection].remove('_id' => id)

    QueryTasks.live_query_pool.updated_collection(collection, @channel)
  end
end
