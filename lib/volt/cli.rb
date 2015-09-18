# Load in the gemfile
require 'bundler/setup'

require 'thor'
require 'volt/extra_core/extra_core'
require 'volt/cli/generators'
require 'volt/cli/generate'
require 'volt/cli/destroy'
require 'volt/version'
require 'volt/cli/bundle'

module Volt
  class CLI < Thor
    include Thor::Actions
    include Volt::Bundle

    register(Generate, 'generate', 'generate GENERATOR [args]', 'Run a generator.')
    register(Destroy, 'destroy', 'destroy GENERATOR [args]', 'Delete files created by a generator.')

    desc 'new PROJECT_NAME', 'generates a new project.'

    def new(name)
      new_project(name)

      say ""
      say "Your app is now ready in the #{name} directory.", :green
      say ""
      say "To run your app: "
      say ""
      say "  cd #{name}"
      say "  bundle exec volt server"
    end


    desc 'console', 'run the console on the project in the current directory'

    def console
      require 'volt/cli/console'
      Console.start
    end

    desc 'server', 'run the server on the project in the current directory'
    method_option :port, type: :string, aliases: '-p', banner: 'the port the server should run on'
    method_option :bind, type: :string, aliases: '-b', banner: 'the ip the server should bind to'

    def server
      move_to_root
      if ENV['PROFILE_BOOT']
        begin
          require 'ruby-prof'

          RubyProf.start
        rescue LoadError => e
          puts "To run volt in a profile mode, you must add ruby-prof gem to the app's Gemfile"
        end
      end

      require 'fileutils'
      require 'volt/server'
      require 'volt/utils/recursive_exists'

      # If we're in a Volt project, clear the temp directory
      # TODO: this is a work around for a bug when switching between
      # source maps and non-source maps.
      if RecursiveExists.exists_here_or_up?('config.ru') && RecursiveExists.exists_here_or_up?('Gemfile')
        # FileUtils.rm_rf('tmp/sass')
        # FileUtils.rm_rf('tmp/sprockets')
      else
        say('Current folder is not a Volt project', :red)
        return
      end

      ENV['SERVER'] = 'true'

      app = Volt::Server.new.app

      server = Rack::Handler.get(RUNNING_SERVER)

      opts = {}
      opts[:Port] = options[:port] || 3000
      opts[:Host] = options[:bind] if options[:bind]

      server.run(app, opts) do |server|
        case RUNNING_SERVER
        when 'thin'
          server.maximum_persistent_connections = 300
          server.maximum_connections = 500 unless Gem.win_platform?
          server.threaded = true

          # We need to disable the timeout on thin, otherwise it will keep
          # disconnecting the websockets.
          server.timeout = 0
        end
      end
    end

    desc 'runner FILEPATH', 'Runs a ruby file at FILEPATH in the volt app'
    method_option :file_path, type: :string
    def runner(file_path)
      ENV['SERVER'] = 'true'
      move_to_root
      require 'volt/cli/runner'

      Volt::CLI::Runner.run_file(file_path)
    end

    desc 'drop_collection NAME', 'Drop a Collection in your MongoDB'

    def drop_collection(collection)
      ENV['SERVER'] = 'true'
      move_to_root
      require 'volt/boot'

      Volt.boot(Dir.pwd)

      db = Volt::DataStore.fetch
      drop = db.drop_collection(collection)

      say("Collection #{collection} could not be dropped", :red) if drop == false
      say("Collection #{collection} dropped", :green) if drop == true
    end

    no_tasks do
      # The logic for creating a new project.  We want to be able to invoke this
      # inside of a method so we can run it with Dir.chdir
      def new_project(name, skip_gemfile = false, disable_encryption = false)
        require 'securerandom'

        # Grab the current volt version
        directory('project', name, {
          version: Volt::Version::STRING,
          name: name,
          domain: name.dasherize.downcase,
          app_name: name.capitalize,
          disable_encryption: disable_encryption
        })

        unless skip_gemfile
          # Move into the directory
          Dir.chdir(name) do
            # bundle
            bundle_command('install')
          end
        end
      end

      def move_to_root
        unless Gem.win_platform?
          # Change CWD to the root of the volt project
          pwd = Dir.pwd
          changed = false
          loop do
            if File.exists?(pwd + '/config.ru') || File.exists?(pwd + '/Gemfile')
              Dir.chdir(pwd) if changed
              break
            else
              changed = true

              # Move up a directory and try again
              pwd = pwd.gsub(/\/[^\/]+$/, '')

              if pwd == ''
                puts "You are not currently in a volt project directory"
                exit 1
              end
            end
          end
        end
      end
    end

    def self.source_root
      File.expand_path(File.join(File.dirname(__FILE__), '../../templates'))
    end
  end
end

# Add in more features
require 'volt/cli/asset_compile'

puts "Volt #{Volt::Version::STRING}"
Volt::CLI.start(ARGV)
