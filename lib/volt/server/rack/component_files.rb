require 'volt/server/rack/component_paths'

# Takes in the path to a component and gets all other components
# required from this one
class ComponentFiles
  def initialize(component_name, asset_files)
    @component_name = component_name
    @asset_files = asset_files
    @components = []
  end
  
  def component(name)
    @components << name
    
    # Load any sub-requires
  end
  
  def path_to_component
    @component_name
  end
  
  def required_components
    path_to_dependencies = File.join(path_to_component, "config/dependencies.rb")
    
    code = File.read(path_to_dependencies)
    
    instance_eval(code)
    
    return @components.uniq
  end
end