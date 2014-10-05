require 'mongo'

class DataStore
  def initialize
  end

  def db
    @@db ||= Volt::DataStore.fetch
  end

  def query(collection, query)
    query = query.dup
    query.keys.each do |key|
      if key =~ /_id$/
        # query[key] = BSON::ObjectId(query[key])
      end
    end

    db[collection].find(query).to_a
  end
end
