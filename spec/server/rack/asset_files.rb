require 'volt/server/rack/asset_files'

describe AssetFiles do
  before do
    @spec_app_root = File.join(File.dirname(__FILE__), "../../app")
  end
  
  it "should return the path to a component" do
    path_to_main = File.join(File.dirname(__FILE__), "../../app/main")
    component_paths = ComponentPaths.new(@spec_app_root))
    
    components = main.required_components
    expect(components).to eq(['shared'])
  end
end
