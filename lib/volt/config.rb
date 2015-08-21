# Config lets a user set global config options for Volt.
# The hash is setup on the server, then the settings under .public are passed
# to the client on initial page render.  Volt.configure can be called multiple
# times and settings will be added to the existing configuration.
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
      attr_reader :config

      # Called on page load to pass the backend config to the client
      def setup_client_config(config_hash)
        # Only Volt.config.public is passed from the server (for security reasons)
        @config = wrap_config(public: config_hash)
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
        opts = {
          app_name:  app_name,
          db_name:   (ENV['DB_NAME'] || (app_name + '_' + Volt.env.to_s)).gsub('.', '_'),
          db_host:   ENV['DB_HOST'] || 'localhost',
          db_port:   (ENV['DB_PORT'] || 27_017).to_i,
          db_driver: ENV['DB_DRIVER'] || 'mongo',

          # a list of components which should be included in all components
          default_components: ['volt'],

          compress_javascript: Volt.env.production?,
          compress_css:        Volt.env.production?,
          compress_images:     Volt.env.production?,
          abort_on_exception:  true,

          min_worker_threads: 1,
          max_worker_threads: 10,
          worker_timeout: 60
        }

        opts[:db_uri] = ENV['DB_URI'] if ENV['DB_URI']

        opts
      end

      # Resets the configuration to the default (empty hash)
      def reset_config!
        configure do |c|
          c.from_h(defaults)
        end
      end

      alias_method :setup,  :configure
      alias_method :config, :configuration
    end

    inst = self
    configuration_defaults do |c|
      current_config = inst.instance_variable_get(:@configuration)
      if current_config
        # Default to the existing config, so we can extend
        c.from_h(current_config.to_h)
      else
        # First call
        c.from_h(Volt.defaults)
      end
    end
  end
end
