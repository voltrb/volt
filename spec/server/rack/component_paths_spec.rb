require 'volt/server/rack/component_paths'

describe ComponentPaths do
  before do
    @spec_app_root = File.join(File.dirname(__FILE__), "../../app")
  end
  
  it "should return the path to a component" do
    path_to_main = File.join(File.dirname(__FILE__), "../../app/main")
    component_paths = ComponentPaths.new(@spec_app_root)
    
    main_path = component_paths.component_path('main')
    expect(main_path).to eq('')
  end
end
