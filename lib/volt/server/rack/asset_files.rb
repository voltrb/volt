# Used to get a list of the assets and other included components
# from the dependencies.rb files.
class AssetFiles
  def initialize(component_name, component_paths)
    @component_paths = component_paths
    @assets = []
    @included_components = {}
    @components = []

    component('volt')
    component(component_name)
  end

  def load_dependencies(path)
    if path
      dependencies_file = File.join(path, "config/dependencies.rb")
    else
      raise "Unable to find component #{component_name.inspect}"
    end

    if File.exists?(dependencies_file)
      # Run the dependencies file in this asset files context
      code = File.read(dependencies_file)
      instance_eval(code)
    end
  end

  def component(name)
    unless @included_components[name]
      # Get the path to the component
      path = @component_paths.component_path(name)

      # Track that we added
      @included_components[name] = true

      # Load the dependencies
      load_dependencies(path)

      # Add any assets
      add_assets(path)
      @components << [path, name]
    end
  end

  def components
    @included_components.keys
  end

  def javascript_file(url)
    @assets << [:javascript_file, url]
  end

  def css_file(url)
    @assets << [:css_file, url]
  end

  def component_paths
    return @components
  end

  def add_assets(path)
    asset_folder = File.join(path, 'assets')
    if File.directory?(asset_folder)
      @assets << [:folder, asset_folder]
    end
  end


  def javascript_files(opal_files)
    javascript_files = []
    @assets.each do |type, path|
      case type
      when :folder
        javascript_files += Dir["#{path}/**/*.js"].sort.map {|folder| '/assets' + folder[path.size..-1] }
      when :javascript_file
        javascript_files << path
      end
    end

    opal_js_files = []
    if Volt.source_maps?
      opal_js_files += opal_files.environment['volt/page/page'].to_a.map {|v| '/assets/' + v.logical_path + '?body=1' }
    else
      opal_js_files << '/assets/volt/page/page.js'
    end
    opal_js_files << '/components/main.js'

    javascript_files += opal_js_files

    return javascript_files
  end

  def css_files
    css_files = []
    @assets.each do |type, path|
      case type
      when :folder
        css_files += Dir["#{path}/**/*.{css,scss}"].sort.map {|folder| '/assets' + folder[path.size..-1].gsub(/[.]scss$/, '') }
      when :css_file
        css_files << path
      end
    end

    return css_files
  end

end
