require 'mongo'

class DataStore
  def initialize
  end

  def db
    @@db ||= Volt::DataStore.fetch
  end

  def query(collection, query)
    allowed_methods = ['find', 'skip', 'limit']

    cursor = db[collection]

    query.each do |query_part|
      method_name, *args = query_part

      unless allowed_methods.include?(method_name.to_s)
        raise "`#{method_name}` is not part of a valid query"
      end

      cursor = cursor.send(method_name, *args)
    end

    cursor.to_a
  end

  def drop_database
    db.connection.drop_database(Volt.config.db_name)
  end

end
