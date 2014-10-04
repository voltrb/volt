# Config lets a user set global config options for Volt.
class Volt

  def self.setup
    yield self.config
  end

  def self.config
    @config || self.reset_config!
  end

  # Resets the configuration to the default (empty hash)
  def self.reset_config!
    app_name = File.basename(Dir.pwd)

    @config = OpenStruct.new({
      app_name: app_name,
      db_name: ENV['DB_NAME'] || (app_name + '_' + Volt.env.to_s),
      db_host: ENV['DB_HOST'] || 'localhost',
      db_port: (ENV['DB_PORT'] || 27017).to_i,
      db_driver: ENV['DB_DRIVER'] || 'mongo'
    })
  end

  # Load in all .rb files in the config folder
  def self.run_files_in_config_folder
    Dir[Dir.pwd + '/config/*.rb'].each do |config_file|
      require(config_file)
    end
  end
end