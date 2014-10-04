ENV['SERVER'] = 'true'

require 'opal'
if RUBY_PLATFORM == 'java'
  require 'jubilee'
else
  require 'thin'
end

require "rack"
if RUBY_PLATFORM != 'java'
  require "rack/sockjs"
  require "eventmachine"
end
require "sass"
require "sprockets-sass"
require 'listen'

require 'volt'
require 'volt/boot'
require 'volt/server/component_handler'
if RUBY_PLATFORM != 'java'
  require 'volt/server/socket_connection_handler'
end
require 'volt/server/rack/component_paths'
require 'volt/server/rack/index_files'
require 'volt/server/rack/opal_files'
require 'volt/tasks/dispatcher'

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

class Server
  def initialize(root_path=nil)
    root_path ||= Dir.pwd
    Volt.root = root_path

    @app_path = File.expand_path(File.join(root_path, "app"))

    # Boot the volt app
    @component_paths = Volt.boot(root_path)

    setup_change_listener

    display_welcome
  end

  def display_welcome
    puts File.read(File.join(File.dirname(__FILE__), "server/banner.txt"))
  end

  def setup_change_listener
    # Setup the listeners for file changes
    listener = Listen.to("#{@app_path}/") do |modified, added, removed|
      puts "file changed, sending reload"
      SocketConnectionHandler.send_message_all(nil, 'reload')
    end
    listener.start
  end

  def app
    @app = Rack::Builder.new

    # Should only be used in production
    if Volt.config.deflate
      @app.use Rack::Deflater
      @app.use Rack::Chunked
    end

    @app.use Rack::ContentLength

    @app.use Rack::KeepAlive
    @app.use Rack::ConditionalGet
    @app.use Rack::ETag

    @app.use Rack::CommonLogger
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

    component_paths.require_in_components

    # Handle socks js connection
    if RUBY_PLATFORM != 'java'
      SocketConnectionHandler.dispatcher = Dispatcher.new

      @app.map "/channel" do
        run Rack::SockJS.new(SocketConnectionHandler)#, :websocket => false
      end
    end

    @app.use Rack::Static,
      :urls => ["/"],
      :root => "public",
      :index => "",
      :header_rules => [
        [:all, {'Cache-Control' => 'public, max-age=86400'}]
      ]

    @app.run lambda{ |env| [ 404, { 'Content-Type'  => 'text/html; charset=utf-8' }, ['404 - page not found'] ] }

    return @app
  end
end
