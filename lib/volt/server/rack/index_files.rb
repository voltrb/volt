require 'volt/server/rack/component_files'
require 'volt/router/routes'

# Serves the main pages
class IndexFiles
  def initialize(app, component_paths, opal_files)
    @app = app
    @component_paths = component_paths
    @opal_files = opal_files
    
    @@router ||= Routes.new.define do
      # Find the route file
      route_file = File.read('app/home/config/routes.rb')
      eval(route_file)
    end
  end
  
  def route_match?(path)
    @@router.path_matchers.each do |path_matcher|
      return true if path =~ path_matcher
    end
    
    return false
  end

  def call(env)
    if route_match?(env['PATH_INFO'])
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
  
  def javascript_files
    # TODO: Cache somehow, this is being loaded every time
    ComponentFiles.new('home', @component_paths, true).javascript_files(@opal_files)
  end
  
  def css_files
    ComponentFiles.new('home', @component_paths, true).css_files
  end

  

end


