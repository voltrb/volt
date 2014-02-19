# Takes in the name and all component paths and has a .code
# method that returns all of the ruby setup code for the component.
class ComponentCode
  def initialize(component_name, component_paths)
    @component_name = component_name
    @component_paths = component_paths
  end

  def code
    code = ''

    asset_files = AssetFiles.new(@component_name, @component_paths)
    asset_files.component_paths.each do |component_path, component_name|
      code << ComponentTemplates.new(component_path, component_name).code
      code << "\n\n"
    end

    return code
  end
end