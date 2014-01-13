require 'volt/server/rack/component_paths'

describe ComponentPaths do
  before do
    spec_app_root = File.join(File.dirname(__FILE__), "../../app")
    
    path_to_main = File.join(File.dirname(__FILE__), "../../app/main")
    @component_paths = ComponentPaths.new(spec_app_root)
  end
  
  it "should return the paths to all app folders" do
    expect(@component_paths.app_folders).to eq([''])
  end
  
  it "should return the path to a component" do
    main_path = @component_paths.component_path('main')
    expect(main_path).to eq('')
  end
end
