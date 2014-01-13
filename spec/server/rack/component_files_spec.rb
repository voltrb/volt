require 'volt/server/rack/component_files'

describe ComponentFiles do
  before do
    spec_app_root = File.join(File.dirname(__FILE__), "../..")
    
    path_to_main = File.join(File.dirname(__FILE__), "../../app/main")
    @component_paths = ComponentPaths.new(spec_app_root)
  end
  
  it "should return the dependencies list" do
    main = ComponentFiles.new("main", @component_paths)
    
    components = main.components
    expect(components).to eq(['main', 'shared', 'bootstrap'])
  end
  
  it "should list all JS files" do
    main = ComponentFiles.new("main", @component_paths)
    
    expect(main.javascript_files).to eq(["/assets/volt/templates/page.js", "/components/home.js", "/assets/js/test2.js", "/assets/js/test1.js"])
  end
end
