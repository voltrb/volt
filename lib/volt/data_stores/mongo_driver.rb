require 'mongo'

class Volt
  class DataStore
    class MongoDriver
      def self.fetch
        @@mongo_db ||= Mongo::MongoClient.new(Volt.config.db_host, Volt.config.db_path)
        @@db ||= @@mongo_db.db(Volt.config.db_name)

        return @@db
      end
    end
  end
end