if RUBY_PLATFORM != 'opal'
  require 'volt/server/rack/asset_files'

  describe AssetFiles do
    before do
      spec_app_root = File.join(File.dirname(__FILE__), "../../apps/file_loading")

      path_to_main = File.join(File.dirname(__FILE__), "../../apps/file_loading/app/main")
      @component_paths = ComponentPaths.new(spec_app_root)
    end

    it "should return the dependencies list" do
      main = AssetFiles.new("main", @component_paths)

      components = main.components
      expect(components).to eq(['volt', 'main', 'shared', 'bootstrap', "slideshow"])
    end

    it "should list all JS files" do
      main = AssetFiles.new("main", @component_paths)

      expect(main.javascript_files(nil)).to eq(["/assets/js/jquery-2.0.3.js", "/assets/js/setImmediate.js", "/assets/js/sockjs-0.3.4.min.js", "/assets/js/vertxbus.js", "/assets/js/bootstrap.js", "/assets/js/test2.js", "/assets/js/test3.js", "/assets/js/test1.js", "/assets/volt/page/page.js", "/components/main.js"])
    end
  end
end
