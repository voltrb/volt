require 'mongo'
class StoreTasks
  def initialize(channel=nil)
    @@mongo_db ||= Mongo::MongoClient.new("localhost", 27017)
    @@db ||= @@mongo_db.db("development")
    
    @channel = channel
  end
  
  def save(collection, data)
    puts "Insert: #{data.inspect} on #{collection}"
    # Try to create
    # TODO: Seems mongo is dumb and doesn't let you upsert with custom id's
    begin
      @@db[collection].insert(data)
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
  end
  
  def find(collection, query=nil)
    puts "FIND: #{collection.inspect}"
    @channel.send_message('update', collection, @@db[collection].find.to_a)
  end
end