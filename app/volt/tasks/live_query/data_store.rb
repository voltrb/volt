require 'mongo'

class DataStore
  def initialize
  end

  def db
    @@db ||= Volt::DataStore.fetch
  end

  def query(collection, query)
    # Extract query parts
    query, skip, limit = query

    # query = query.dup
    # query.keys.each do |key|
    #   if key =~ /_id$/
    #     # query[key] = BSON::ObjectId(query[key])
    #   end
    # end

    # db[collection].find(query).to_a

    puts "QUERY: #{query.inspect} - #{skip.inspect} - #{limit.inspect}"

    cursor = db[collection].find(query)
    cursor = cursor.skip(skip) if skip
    cursor = cursor.limit(limit) if limit

    return cursor.to_a
  end
end
