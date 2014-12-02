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

    cursor = db[collection].find(query)
    cursor = cursor.skip(skip) if skip
    cursor = cursor.limit(limit) if limit

    cursor.to_a
  end

  def drop_database
    db.connection.drop_database(Volt.config.db_name)
  end
end
