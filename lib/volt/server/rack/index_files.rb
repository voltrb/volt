require 'volt/server/rack/component_files'

# Serves the main pages
class IndexFiles
  def initialize(app, component_paths)
    @app = app
    @component_paths = component_paths
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
  
  def javascript_files
    # TODO: Cache somehow, this is being loaded every time
    ComponentFiles.new('home', @component_paths, true).javascript_files
  end
  
  def css_files
    ComponentFiles.new('home', @component_paths).css_files
  end

  

end


