require 'mongo'

module Volt
  class DataStore
    class MongoDriver
      def self.fetch
        if Volt.config.db_uri.present?
          @@mongo_db ||= Mongo::MongoClient.from_uri(Volt.config.db_uri)
          @@db ||= @@mongo_db.db(Volt.config.db_uri.split('/').last || Volt.config.db_name)
        else
          @@mongo_db ||= Mongo::MongoClient.new(Volt.config.db_host, Volt.config.db_path)
          @@db ||= @@mongo_db.db(Volt.config.db_name)
        end
        @@db
      end
    end
  end
end
