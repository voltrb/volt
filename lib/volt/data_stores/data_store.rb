require 'volt/data_stores/base_adaptor_server'

module Volt
  class DataStore
    def self.fetch
      # Cache the driver
      return @adaptor if @adaptor

      database_name = Volt.config.db_driver
      adaptor_name = database_name.camelize + 'AdaptorServer'

      root = Volt::DataStore
      if root.const_defined?(adaptor_name)
        adaptor_name = root.const_get(adaptor_name)
        @adaptor = adaptor_name.new
      else
        raise "#{database_name} is not a supported database, you might be missing a volt-#{database_name} gem"
      end

      @adaptor
    end

    def self.adaptor_client
      # Load the client adaptor
      @adaptor_client ||= begin
        ds_name = Volt.config.public.datastore_name
        unless ds_name
          raise "No data store configured, please include volt-mongo or " +
                "another similar gem."
        end
        adaptor_class_name = ds_name.capitalize + "AdaptorClient"
        Volt::DataStore.const_get(adaptor_class_name)
      end
    end
  end
end
