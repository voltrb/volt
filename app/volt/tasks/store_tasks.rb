require 'mongo'
require_relative 'channel_tasks'

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
  
  def save(collection, data)
    puts "Insert: #{data.inspect} on #{collection.inspect}"
    
    data = data.symbolize_keys
    id = data[:_id]

    # Try to create
    # TODO: Seems mongo is dumb and doesn't let you upsert with custom id's
    begin
      @@db[collection].insert(data)
      
      # Message that we inserted a new item
      puts "SENDING DATA: #{data.inspect}"
      ChannelTasks.send_message_to_channel("#{collection}-added", ['added', nil, collection, data], @channel)
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
    

    ChannelTasks.send_message_to_channel("#{collection}##{id}", ['changed', nil, id, data], @channel)
  end
  
  def find(collection, scope, query=nil)
    results = @@db[collection].find(scope).to_a.map {|item| item.symbolize_keys }
    puts "FIND: #{collection.inspect} - #{scope} - #{results.inspect}"
    
    return results
  end
  
  def delete(collection, id)
    puts "DELETE: #{collection.inspect} - #{id.inspect}"
    @@db[collection].remove('_id' => id)
    
    ChannelTasks.send_message_to_channel("#{collection}-removed", ['removed', nil, id], @channel)
  end
end