require "volt/data_stores/mongo_driver"

module Volt
  class DataStore
    def self.fetch
      db_driver = Volt.config.db_driver

      case db_driver
      when 'mongo'
        MongoDriver.fetch
      else
        fail "Could not resolve the db specified in Volt.config.db_driver: #{db_driver}"
      end
    end

  end
end
