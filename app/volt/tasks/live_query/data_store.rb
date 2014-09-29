require 'mongo'

class DataStore
  def initialize
    @@mongo_db ||= Mongo::MongoClient.new(
      Volt.config.db[:host], Volt.config.db[:port]
    )
    @@db ||= @@mongo_db.db(Volt.config.db[:name])
  end

  def query(collection, query)
    puts "QUERY: #{collection} - #{query.inspect}"

    query = query.dup
    query.keys.each do |key|
      if key =~ /_id$/
        # query[key] = BSON::ObjectId(query[key])
      end
    end

    @@db[collection].find(query).to_a
  end
end
