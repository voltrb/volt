require 'mongo'
require 'query_tasks'

class StoreTasks
  def initialize(channel=nil, dispatcher=nil)
    @@mongo_db ||= Mongo::MongoClient.new("localhost", 27017)
    @@db ||= @@mongo_db.db("development")

    @channel = channel
    @dispatcher = dispatcher
  end

  def db
    @@db
  end

  def valid?(collection, data)
    puts "CHECK VALID: #{data.inspect}"
    model_name = collection[1..-1].singularize.camelize

    # TODO: Security check to make sure we have a valid model
    begin
      model_class = Object.send(:const_get, model_name)
    rescue NameError => e
      model_class = nil
    end

    if model_class
      errors = model_class.new(data).errors

      if errors.size > 0
        puts "ERRORS: #{errors.inspect} - #{data.inspect}"
        return false
      end
    end

    return true
  end

  def save(collection, data)
    puts "Insert: #{data.inspect} on #{collection.inspect}"

    data = data.symbolize_keys

    if valid?(collection, data)
      id = data[:_id]

      # Try to create
      # TODO: Seems mongo is dumb and doesn't let you upsert with custom id's
      begin
        @@db[collection].insert(data)
      rescue Mongo::OperationFailure => error
        # Really mongo client?
        if error.message[/^11000[:]/]
          # Update because the id already exists
          update_data = data.dup
          update_data.delete(:_id)
          @@db[collection].update({:_id => id}, update_data)
        else
          raise
        end
      end

      puts "SAVE: #{@channel.inspect}"
      QueryTasks.live_query_pool.updated_collection(collection, @channel)
    end
  end

  def delete(collection, id)
    puts "DELETE: #{collection.inspect} - #{id.inspect}"
    @@db[collection].remove('_id' => id)

    QueryTasks.live_query_pool.updated_collection(collection, @channel)
  end
end
