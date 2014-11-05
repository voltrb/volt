# Config lets a user set global config options for Volt.
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
      Dir[Dir.pwd + '/config/*.rb'].each do |config_file|
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
