# Serves the main pages
class IndexFiles
  def initialize(app, asset_files)
    @app = app
    @asset_files = asset_files
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
    @asset_files.asset_javascript_files
  end
  
  def css_files
    @asset_files.asset_css_files
  end

  

end


