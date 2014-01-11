require 'opal'
require "rack"
if RUBY_PLATFORM != 'java'
  require "rack/sockjs"
  require "eventmachine"
end
require "sprockets-sass"
require "sass"

require 'volt/extra_core/extra_core'
require 'volt/server/component_handler'
if RUBY_PLATFORM != 'java'
  require 'volt/server/channel_handler'
end
require 'volt/server/source_map_server'

class Index

  def initialize(app, javascript_files, css_files)
    @app = app
    @javascript_files = javascript_files
    @css_files = css_files
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
  def initialize
    @app_path = File.expand_path(File.join(Dir.pwd, "app"))
  end
  
  def asset_folders
    @asset_folders ||= begin
      Dir["app/*/views/*/assets"]
    end
  end
  
  def asset_javascript_files
    Dir["app/*/views/*/assets/**/*.js"].map {|path| '/' + path.split('/')[4..-1].join('/') }
  end

  def asset_css_files
    Dir["app/*/views/*/assets/**/*.{css,scss}"].map {|path| '/' + path.split('/')[4..-1].join('/').gsub(/[.]scss$/, '') }
  end
  
  def add_asset_folders(environment)
    asset_folders.each do |asset_folder|
      environment.append_path(asset_folder)
    end
  end
  
  # Sets up the maps for the opal assets, and source maps if enabled.
  def setup_opal
    environment = Opal::Environment.new
    
    environment.append_path(@app_path)
    
    volt_gem_lib_path = File.expand_path(File.join(File.dirname(__FILE__), ".."))
    environment.append_path(volt_gem_lib_path)

      
    add_asset_folders(environment)

    # Add the opal load paths
    Opal.paths.each do |path|
      environment.append_path(path)
    end

    # opal-jquery gem
    spec = Gem::Specification.find_by_name("opal-jquery")
    environment.append_path(spec.gem_dir + "/opal")

    @app.map '/assets' do
      run environment
    end

    if SOURCE_MAPS
      source_maps = SourceMapServer.new(environment)

      @app.map(source_maps.prefix) do
        run source_maps
      end
    end    
  end
  
  def app
    @app = Rack::Builder.new
    @app.use Rack::CommonLogger
    @app.use Rack::ShowExceptions

    @app.map '/components' do
      run ComponentHandler.new
    end


    if SOURCE_MAPS
      javascript_files = environment['volt/templates/page'].to_a.map {|v| '/assets/' + v.logical_path + '?body=1' }
    else
      javascript_files = ['/assets/volt/templates/page.js']
    end
    
    javascript_files << '/components/home.js'
    javascript_files += asset_javascript_files
    
    css_files = []
    css_files += asset_css_files

    @app.use Index, javascript_files, css_files
          
    setup_opal
    
    @app.use Rack::Static,
      :urls => ["/"],
      :root => "public",
      :index => "",
      :header_rules => [
        [:all, {'Cache-Control' => 'public, max-age=86400'}]
      ]
    

    if RUBY_PLATFORM != 'java'
      @app.map "/channel" do
        run Rack::SockJS.new(ChannelHandler)#, :websocket => false
      end
    end

    @app.run lambda{ |env| [ 404, { 'Content-Type'  => 'text/html' }, ['404 - page not found'] ] }
    
    return @app
  end
end