require 'opal'
require "rack"
if RUBY_PLATFORM != 'java'
  require "rack/sockjs"
  require "eventmachine"
end
require "sprockets-sass"
require "sass"
require 'listen'

require 'volt/extra_core/extra_core'
require 'volt/server/component_handler'
if RUBY_PLATFORM != 'java'
  require 'volt/server/channel_handler'
end
require 'volt/server/rack/component_paths'
require 'volt/server/rack/index_files'
require 'volt/server/rack/opal_files'
require 'volt/tasks/dispatcher'


class Server
  def initialize
    @app_path = File.expand_path(File.join(Dir.pwd, "app"))
    @component_paths = ComponentPaths.new
    
    # Setup the listeners for file changes
    puts "Listen for changes on #{@app_path}"
    listener = Listen.to("#{@app_path}/") do |modified, added, removed|
      ChannelHandler.send_message_all(nil, 'reload')
    end
    listener.start
  end
  
  def app
    @app = Rack::Builder.new
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
    
    # Handle socks js connection
    if RUBY_PLATFORM != 'java'
      component_paths.add_tasks_to_load_path
      ChannelHandler.dispatcher = Dispatcher.new
      
      @app.map "/channel" do
        run Rack::SockJS.new(ChannelHandler)#, :websocket => false
      end
    end
    
    @app.use Rack::Static,
      :urls => ["/"],
      :root => "public",
      :index => "",
      :header_rules => [
        [:all, {'Cache-Control' => 'public, max-age=86400'}]
      ]

    @app.run lambda{ |env| [ 404, { 'Content-Type'  => 'text/html' }, ['404 - page not found'] ] }
    
    return @app
  end
end