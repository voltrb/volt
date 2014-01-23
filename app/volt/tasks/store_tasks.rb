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
    # Try to create
    # TODO: Seems mongo is dumb and doesn't let you upsert with custom id's
    begin
      @@db[collection].insert(data)
      id = {'_id' => data.delete('_id')}
      
      # Message that we inserted a new item
      ChannelTasks.send_message_to_channel("#{collection}", ['added', nil, collection, data.merge('_id' => id).symbolize_keys], @channel)
    rescue Mongo::OperationFailure => error
      # Really mongo client?
      if error.message[/^11000[:]/]
        # Update because the id already exists
        id = {'_id' => data.delete('_id')}
        @@db[collection].update(id, data)
      else
        raise
      end
    end
    
    id = id['_id']

    ChannelTasks.send_message_to_channel("#{collection}##{id}", ['changed', nil, id, data.merge('_id' => id).symbolize_keys], @channel)
  end
  
  def find(collection, scope, query=nil)
    results = @@db[collection].find(scope).to_a.map {|item| item.symbolize_keys }
    puts "FIND: #{collection.inspect} - #{scope} - #{results.inspect}"
    
    return results
  end
end