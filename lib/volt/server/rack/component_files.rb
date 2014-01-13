require 'volt/server/rack/component_paths'

SOURCE_MAPS = !!ENV['MAPS'] unless defined?(SOURCE_MAPS)

# Takes in the path to a component and gets all other components
# required from this one
class ComponentFiles
  def initialize(component_name, component_paths)
    @component_name = component_name
    @component_paths = component_paths
    @asset_folders = []
    @components = [component_name]
    
    load_child_components
    add_asset_folder(component_name)
  end
  
  def components
    @components
  end
  
  def component(name)
    # Load any sub-requires
    child_files = ComponentFiles.new(name, @component_paths)
    new_components = child_files.components
    
    # remove any we already have
    new_components = new_components - @components
    new_components.each {|nc| add_asset_folder(nc) }
    
    @components += new_components
    
    return @components
  end
  
  def add_asset_folder(component_name)
    path = path_to_component(component_name)
    
    asset_folder = File.join(path, 'assets')
    if File.directory?(asset_folder)
      @asset_folders << asset_folder
    end
  end
  
  def path_to_component(name=nil)
    @component_paths.component_path(name || @component_name)
  end
  
  def load_child_components
    path = path_to_component
    if path
      dependencies_file = File.join(path_to_component, "config/dependencies.rb")
    else
      raise "Unable to find component #{@component_name.inspect}"
    end
    
    if File.exists?(dependencies_file)
      # Run the dependencies file in this ComponentFiles context
      code = File.read(dependencies_file)
      puts "CODE: #{code.inspect}"
      instance_eval(code)
    end
  end
  
  # Returns every asset folder that is included from this component.
  # This means this components assets folder and any in the dependency chain.
  def asset_folders
    files = []
    @asset_folders.each do |asset_folder|
      files << yield(asset_folder)
    end
    
    return files.flatten
  end
  
  
  def javascript_files
    if SOURCE_MAPS
      javascript_files = environment['volt/templates/page'].to_a.map {|v| '/assets/' + v.logical_path + '?body=1' }
    else
      javascript_files = ['/assets/volt/templates/page.js']
    end
    
    javascript_files << '/components/home.js'
    javascript_files += asset_folders do |asset_folder|
      Dir["#{asset_folder}/**/*.js"].map {|path| '/assets' + path[asset_folder.size..-1] }
    end
    
    return javascript_files
  end

  def css_files
    asset_folders do |asset_folder|
      Dir["#{asset_folder}/**/*.{css,scss}"].map {|path| '/assets' + path[asset_folder.size..-1].gsub(/[.]scss$/, '') }
    end
  end
end