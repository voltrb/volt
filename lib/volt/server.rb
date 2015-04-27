ENV['SERVER'] = 'true'

require 'opal'

require 'rack'
require 'sass'
require 'volt/utils/tilt_patch'
require 'sprockets-sass'
require 'haml'
require 'listen'


require 'volt'
require 'volt/boot'
require 'volt/tasks/dispatcher'
require 'volt/tasks/task_handler'
require 'volt/server/component_handler'
require 'volt/server/rack/component_paths'
require 'volt/server/rack/index_files'
require 'volt/server/rack/http_resource'
require 'volt/server/rack/opal_files'
require 'volt/server/rack/quiet_common_logger'
require 'volt/page/page'

require 'volt/server/rack/http_request'
require 'volt/controllers/http_controller'
require 'volt/server/websocket/websocket_handler'

module Rack
  # TODO: For some reason in Rack (or maybe thin), 304 headers close
  # the http connection.  We might need to make this check if keep
  # alive was in the request.
  class KeepAlive
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)

      if status == 304 && env['HTTP_CONNECTION'].downcase == 'keep-alive'
        headers['Connection'] = 'keep-alive'
      end

      [status, headers, body]
    end
  end
end

module Volt
  class Server

    def initialize(root_path = nil)
      root_path ||= Dir.pwd
      Volt.root = root_path

      @app_path        = File.expand_path(File.join(root_path, 'app'))

      # Boot the volt app
      @component_paths = Volt.boot(root_path)

      setup_router
      require_http_controllers
      setup_change_listener

      display_welcome
    end

    def display_welcome
      puts File.read(File.join(File.dirname(__FILE__), 'server/banner.txt'))
    end

    def setup_router
      # Find the route file
      home_path  = @component_paths.component_paths('main').first
      routes = File.read("#{home_path}/config/routes.rb")
      @router = Routes.new.define do
        eval(routes)
      end
    end

    def require_http_controllers
      @component_paths.app_folders do |app_folder|
        # Sort so we get consistent load order across platforms
        Dir["#{app_folder}/*/controllers/server/*.rb"].each do |ruby_file|
          #path = ruby_file.gsub(/^#{app_folder}\//, '')[0..-4]
          #require(path)
          load ruby_file
        end
      end
    end

    def setup_change_listener
      # Setup the listeners for file changes
      listener = Listen.to("#{@app_path}/") do |modified, added, removed|
        puts 'file changed, sending reload'
        setup_router
        require_http_controllers
        SocketConnectionHandler.send_message_all(nil, 'reload')
      end
      listener.start
    end

    def app
      @app = Rack::Builder.new

      # Handle websocket connections
      @app.use WebsocketHandler

      # Should only be used in production
      if Volt.config.deflate
        @app.use Rack::Deflater
        @app.use Rack::Chunked
      end

      @app.use Rack::ContentLength

      @app.use Rack::KeepAlive
      @app.use Rack::ConditionalGet
      @app.use Rack::ETag

      @app.use QuietCommonLogger
      @app.use Rack::ShowExceptions

      component_paths = @component_paths
      @app.map '/components' do
        run ComponentHandler.new(component_paths)
      end

      # Serve the opal files
      opal_files = OpalFiles.new(@app, @app_path, @component_paths)

      # Serve the main html files from public, also figure out
      # which JS/CSS files to serve.
      @app.use IndexFiles, @component_paths, opal_files

      @app.use HttpResource, @router

      component_paths.require_in_components

      @app.use Rack::Static,
        urls: ['/'],
        root: 'config/base',
        index: '',
        header_rules: [
          [:all, { 'Cache-Control' => 'public, max-age=86400' }]
        ]

      @app.run lambda { |env| [404, { 'Content-Type' => 'text/html; charset=utf-8' }, ['404 - page not found']] }

      @app
    end
  end
end
