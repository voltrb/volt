require 'volt/server/rack/component_paths'

describe ComponentPaths do
  before do
    spec_app_root = File.join(File.dirname(__FILE__), "../..")
    
    path_to_main = File.join(File.dirname(__FILE__), "../../app/main")
    @component_paths = ComponentPaths.new(spec_app_root)
  end
  
  it "should return the paths to all app folders" do
    match_count = 0
    @component_paths.app_folders do |app_folder|
      if app_folder[/spec\/app$/] || app_folder[/spec\/vendor\/app$/]
        match_count += 1
      end
    end
    
    expect(match_count).to eq(2)
  end
  
  it "should return the path to a component" do
    main_path = @component_paths.component_path('main')
    expect(main_path).to match(/spec\/app\/main$/)
  end
end
