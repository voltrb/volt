require 'opal'
require "rack"
if RUBY_PLATFORM != 'java'
  require "rack/sockjs"
  require "eventmachine"
end
require "sprockets-sass"
require "sass"

require 'volt/extra_core/extra_core'
require 'volt/server/request_handler'
require 'volt/server/component_handler'
if RUBY_PLATFORM != 'java'
  require 'volt/server/channel_handler'
end
require 'volt/server/source_map_server'

class Index

  def initialize(app, files)
    @app = app
    @files = files
  end

  def call(env)
    if %w[/ /demo /blog /todos /page3 /page4].include?(env['PATH_INFO']) || env['PATH_INFO'][0..5] == '/todos'
      [200, { 'Content-Type' => 'text/html' }, [html]]
    else
      @app.call env
    end
  end
  
  def html
    index_path = File.expand_path(File.join(Dir.pwd, "public/index.html"))
    html = File.read(index_path)
    
    ERB.new(html).result(binding)
  end
end



SOURCE_MAPS = !!ENV['MAPS']

Opal::Processor.source_map_enabled = SOURCE_MAPS
# Opal::Processor.arity_check_enabled = true
# Opal::Processor.dynamic_require_severity = :raise



class Server
  def self.app

    builder = Rack::Builder.new do
      use Rack::CommonLogger
      # run RequestHandler.new

      use Rack::ShowExceptions

      map '/components' do
        run ComponentHandler.new
      end

      environment = Opal::Environment.new
      
      app_path = File.expand_path(File.join(Dir.pwd, "app"))
      environment.append_path(app_path)
      
      volt_gem_lib_path = File.expand_path(File.join(File.dirname(__FILE__), ".."))
      environment.append_path(volt_gem_lib_path)
  
      # Add the opal load paths
      Opal.paths.each do |path|
        environment.append_path(path)
      end
  
      # opal-jquery gem
      spec = Gem::Specification.find_by_name("opal-jquery")
      environment.append_path(spec.gem_dir + "/opal")

  
      map '/assets' do
        run environment
      end
  
      if SOURCE_MAPS
        source_maps = SourceMapServer.new(environment)
  
        map(source_maps.prefix) do
          run source_maps
        end
      end

      if RUBY_PLATFORM != 'java'
        map "/channel" do
          run Rack::SockJS.new(ChannelHandler)#, :websocket => false
        end
      end

      if SOURCE_MAPS
        files = environment['volt/templates/page'].to_a.map {|v| v.logical_path }
      else
        files = []
      end

      use Index, files

      use Rack::Static,
        :urls => ["/"],
        :root => "public",
        :index => "",
        :header_rules => [
          [:all, {'Cache-Control' => 'public, max-age=86400'}]
        ]
  
      run lambda{ |env| [ 404, { 'Content-Type'  => 'text/html' }, ['404 - page not found'] ] }
    end
    
    return builder
  end
end