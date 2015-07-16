ENV['SERVER'] = 'true'

require 'opal'

require 'rack'
require 'sass'
require 'volt/utils/tilt_patch'

require 'volt'
require 'volt/tasks/dispatcher'
require 'volt/tasks/task'
require 'volt/server/rack/component_code'
require 'volt/server/template_handlers/sprockets_component_handler'

require 'volt/server/websocket/websocket_handler'
require 'volt/utils/read_write_lock'
require 'volt/server/forking_server'
require 'volt/server/websocket/rack_server_adaptor'


module Volt
  class Server
    attr_reader :listener, :app_path

    # You can also optionally pass in a prebooted app
    def initialize(root_path = nil, app = nil)
      @root_path = root_path || Dir.pwd
      @volt_app = app

      @app_path = File.expand_path(File.join(@root_path, 'app'))

      display_welcome
    end

    def display_welcome
      puts File.read(File.join(File.dirname(__FILE__), 'server/banner.txt'))
    end

    def boot_volt
      # Boot the volt app
      require 'volt/boot'

      @volt_app ||= Volt.boot(@root_path)
    end

    # App returns the main rack app.  In development it will use ForkingServer,
    # which forks the app and processes responses in a child process, that is
    # killed when code changes and reforked.  (This provides simple fast code
    # reloading)
    def app
      # Setup the rack server and adaptor
      RackServerAdaptor.load

      app = Rack::Builder.new

      # Handle websocket connections
      app.use WebsocketHandler

      can_fork = Process.respond_to?(:fork)

      unless can_fork
        Volt.logger.warn('Code reloading in Volt currently depends on `fork`.  Your environment does not support `fork`.  We\'re working on adding more reloading strategies.  For now though you\'ll need to restart the server manually on changes, which sucks.  Feel free to complain to the devs, we really let you down here. :-)')
      end

      # Only run ForkingServer if fork is supported in this env.
      # NO_FORKING can be used to specify that you don't want to use the forking
      # server.
      if !can_fork || Volt.env.production? || Volt.env.test? || ENV['NO_FORKING']
        # In production/test, we boot the app and run the server
        #
        # Sometimes the app is already booted, so we can skip if it is
        boot_volt unless @volt_app

        # Setup the dispatcher (it stays this class during its run)
        SocketConnectionHandler.dispatcher = Dispatcher.new(@volt_app)
        app.run(@volt_app.middleware)
      else
        # In developer
        app.run ForkingServer.new(self)
      end

      app
    end
  end
end
