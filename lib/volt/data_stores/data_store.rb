require 'volt/data_stores/mongo_driver'

module Volt
  class DataStore
    def self.fetch
      if Volt.config.db_driver == 'mongo'
        MongoDriver.fetch
      else
        fail "#{database_name} is not a supported database"
      end
    end
  end
end
