require 'volt/data_stores/mongo_driver'

module Volt
  class DataStore
    def self.fetch
      # Cache the driver
      return @driver if @driver

      database_name = Volt.config.db_driver
      driver_name = database_name.camelize + 'Driver'

      begin
        driver = self.const_get(driver_name)
        @driver = MongoDriver.new
      rescue NameError => e
        fail "#{database_name} is not a supported database"
      end
    end
  end
end
