if RUBY_PLATFORM != 'opal'
  require 'spec_helper'
  require 'volt/server/rack/asset_files'

  describe Volt::AssetFiles do
    before do
      spec_app_root = File.join(File.dirname(__FILE__), '../../apps/file_loading')

      @component_paths = Volt::ComponentPaths.new(spec_app_root)
    end

    it 'should return the dependencies list' do
      main = Volt::AssetFiles.new('main', @component_paths)

      components = main.components
      expect(components).to eq(%w(volt mongo main shared bootstrap slideshow))
    end

    it 'should list all JS files' do
      main = Volt::AssetFiles.new('main', @component_paths)
      expect(main.javascript_files(nil)).to eq(['/volt/assets/js/jquery-2.0.3.js', '/volt/assets/js/volt_js_polyfills.js', '/volt/assets/js/bootstrap.js', '/volt/assets/js/test2.js', '/volt/assets/js/test3.js', '/volt/assets/js/test1.js', '/volt/assets/volt/page/page.js', '/volt/components/main.js'])
    end

    it 'should raise an exception for a missing component gem' do
      main = Volt::AssetFiles.new('main', @component_paths)

      relative_dep_path = '../../apps/file_loading/app/missing_deps'
      path_to_missing_deps = File.join(File.dirname(__FILE__), relative_dep_path)
      expect do
        main.load_dependencies(path_to_missing_deps)
      end.to raise_error("Unable to find component 'a-gem-that-isnt-in-the-gemfile', make sure the gem is included in your Gemfile")
    end

    it 'should not raise an exception for a dependency file with valid components' do
      main = Volt::AssetFiles.new('main', @component_paths)

      path_to_main = File.join(File.dirname(__FILE__), '../../apps/file_loading/app/main')
      path_to_missing_deps = File.join(File.dirname(__FILE__), path_to_main)
      expect do
        main.load_dependencies(path_to_missing_deps)
      end.to_not raise_error
    end
  end
end
