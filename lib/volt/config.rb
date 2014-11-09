# Config lets a user set global config options for Volt.
# The hash is setup on the server, then passed to the client on initial page render.
if RUBY_PLATFORM == 'opal'
  require 'ostruct'

  # TODO: Temporary fix for missing on OpenStruct in opal
  class OpenStruct
    def respond_to?(method_name)
      @table.key?(method_name) || super
    end
  end

  module Volt
    class << self
      # Returns the config
      def config
        @config
      end

      # Called on page load to pass the backend config to the client
      def setup_client_config(config_hash)
        # Only Volt.config.public is passed from the server (for security reasons)
        @config = wrap_config({public: config_hash})
      end

      # Wraps the config hash in an OpenStruct so it can be accessed in the same way
      # as the server side config.
      def wrap_config(hash)
        new_hash = {}

        hash.each_pair do |key, value|
          if value.is_a?(Hash)
            new_hash[key] = wrap_config(value)
          else
            new_hash[key] = value
          end
        end

        OpenStruct.new(new_hash)
      end
    end
  end
else
  require 'configurations'
  module Volt
    include Configurations

    class << self
      def defaults
        app_name = File.basename(Dir.pwd)
        {
            app_name:  app_name,
            db_name:   ENV['DB_NAME'] || (app_name + '_' + Volt.env.to_s),
            db_host:   ENV['DB_HOST'] || 'localhost',
            db_port:   (ENV['DB_PORT'] || 27_017).to_i,
            db_driver: ENV['DB_DRIVER'] || 'mongo',
          }
      end

      # Resets the configuration to the default (empty hash)
      def reset_config!
        self.configure do |c|
          c.from_h(defaults)
        end
      end

      # Load in all .rb files in the config folder
      def run_files_in_config_folder
        Dir[Volt.root + '/config/*.rb'].each do |config_file|
          require(config_file)
        end
      end

      alias_method :setup,  :configure
      alias_method :config, :configuration
    end

    configuration_defaults do |c|
      c.from_h(Volt.defaults)
    end
  end
end
