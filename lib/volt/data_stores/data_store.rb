require 'volt/data_stores/mongo_driver'

module Volt
  class DataStore
    def self.fetch
      if Volt.config.db_driver == 'mongo'
        return MongoDriver.fetch
      else
        fail "Could not resolve the db specified in Volt.config.db_driver: #{Volt.config.db_driver}"
      end
    end

  end
end
