require 'volt/server/rack/component_files'

describe ComponentFiles do
  before do
    @spec_app_root = File.join(File.dirname(__FILE__), "../../app")
  end
  
  it "should return the dependencies list" do
    path_to_main = File.join(File.dirname(__FILE__), "../../app/main")
    main = ComponentFiles.new(path_to_main, ComponentPaths.new(@spec_app_root))
    
    components = main.required_components
    expect(components).to eq(['shared'])
  end
end
