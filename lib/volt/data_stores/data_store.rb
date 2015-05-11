require 'volt/data_stores/mongo_driver'

module Volt
  class DataStore
    def self.fetch
      # Cache the driver
      return @driver if @driver

      database_name = Volt.config.db_driver
      driver_name = database_name.camelize + 'Driver'

      root = Volt::DataStore
      if root.const_defined?(driver_name)
        driver = root.const_get(driver_name)
        @driver = driver.new
      else
        raise "#{database_name} is not a supported database"
      end
    end
  end
end
