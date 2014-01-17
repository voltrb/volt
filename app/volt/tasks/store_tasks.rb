require 'mongo'
class StoreTasks
  def initialize(channel=nil)
    @@mongo_db ||= Mongo::MongoClient.new("localhost", 27017)
    @@db ||= @@mongo_db.db("development")
    
    @channel = channel
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
    
    puts "CHECK: #{id.inspect} - #{data.inspect}"
    id = id['_id']
    # ChannelHandler.send_message_all('update', nil, id, data.merge('_id' => id))
  end
  
  def find(collection, scope, query=nil)
    puts "FIND: #{collection.inspect} - #{scope}"
    return @@db[collection].find(scope).to_a
  end
end