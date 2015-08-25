if RUBY_PLATFORM != 'opal'
  require 'spec_helper'
  require 'volt/server/rack/asset_files'
  require 'volt/server/template_handlers/sprockets_component_handler'

   describe Volt::AssetFiles do
    before do
      spec_app_root = File.join(File.dirname(__FILE__), '../../apps/file_loading')

      @component_paths = Volt::ComponentPaths.new(spec_app_root)
    end

    it 'should return the dependencies list' do
      main = Volt::AssetFiles.new('/app', 'main', @component_paths)

      components = main.components
      expect(components).to eq(%w(volt mongo main shared bootstrap slideshow))
    end

    describe 'js files' do
      context "when the component's dependencies.rb does not contain .disable_auto_import" do
        it 'should list all JS files' do
          main = Volt::AssetFiles.new('/app', 'main', @component_paths)
          expect(main.javascript(volt_app).reject{|v| v[0] != :src }).to eq([
            [:src, "/app/volt/assets/js/jquery-2.0.3.js"],
            [:src, "/app/volt/assets/js/volt_js_polyfills.js"],
            [:src, "/app/volt/assets/js/volt_watch.js"],
            [:src, "/app/bootstrap/assets/js/bootstrap.js"],
            [:src, "/app/shared/assets/js/test2.js"],
            [:src, "/app/slideshow/assets/js/test3.js"],
            [:src, "/app/main/assets/js/test1.js"],
            [:src, "/app/volt/volt/app.js"],
            [:src, "/app/components/main.js"]
          ])
        end
      end

      context "when the component's dependencies.rb contains .disable_auto_import" do
        it 'should list only the files included via the css_file helpers' do
          disabled_auto = Volt::AssetFiles.new('/app', 'disable_auto', @component_paths)
          expect(disabled_auto.javascript(volt_app).reject{|v| v[0] != :src }).to eq([
            [:src, "/app/volt/assets/js/jquery-2.0.3.js"],
            [:src, "/app/volt/assets/js/volt_js_polyfills.js"],
            [:src, "/app/volt/assets/js/volt_watch.js"],
            [:src, "/app/disable_auto/assets/js/test1.js"],
            [:src, "/app/volt/volt/app.js"],
            [:src, "/app/components/main.js"]
          ])
        end
      end
    end

    describe 'css files' do

      context "when the component's dependencies.rb does not contain .disable_auto_import" do
        it 'should list all the asset files in that component' do
          main = Volt::AssetFiles.new('/app', 'main', @component_paths)

          expect(main.css).to eq([
            "/app/volt/assets/css/notices.css",
            "/app/bootstrap/assets/css/01-bootstrap.css",
            "/app/main/assets/css/test3.css"
          ])
        end
      end

      context "when the component's dependencies.rb contains .disable_auto_import" do
        it 'should list only the files included via the css_file helpers' do
          disabled_auto = Volt::AssetFiles.new('/app', 'disable_auto', @component_paths)

          expect(disabled_auto.css).to eq([
            "/app/volt/assets/css/notices.css",
            "/app/disable_auto/assets/css/test1.css"
          ])
        end
      end
    end

    describe '.is_url?' do
      it 'should return true for URIs like //something.com/something.js' do
        main = Volt::AssetFiles.new('/app', 'main', @component_paths)
        expect(main.url_or_path? '//something.com/a-folder/something.js').to eq(true)
      end

      it 'should return true for HTTP and HTTPS urls' do
        main = Volt::AssetFiles.new('/app', 'main', @component_paths)
        expect(main.url_or_path? 'http://something.com/a-folder/something.js').to eq(true)
        expect(main.url_or_path? 'https://something.com/a-folder/something.js').to eq(true)
      end

      it 'should return true for paths' do
        main = Volt::AssetFiles.new('/app', 'main', @component_paths)
        expect(main.url_or_path? 'something.js').to eq(false)
        expect(main.url_or_path? '/app/something.js').to eq(true)
        expect(main.url_or_path? '/app/something/something.js').to eq(true)
      end

      it 'should return false for file names' do
        main = Volt::AssetFiles.new('/app', 'main', @component_paths)
        expect(main.url_or_path? 'something.js').to eq(false)
        expect(main.url_or_path? 'app/something/something.js').to eq(false)
      end

    end

    it 'should raise an exception for a missing component gem' do
      main = Volt::AssetFiles.new('/app', 'main', @component_paths)

      relative_dep_path = '../../apps/file_loading/app/missing_deps'
      path_to_missing_deps = File.join(File.dirname(__FILE__), relative_dep_path)
      component_name = 'a-gem-that-isnt-in-the-gemfile'
      expect do
        main.load_dependencies(path_to_missing_deps, component_name)
      end.to raise_error("Unable to find component '#{component_name}', make sure the gem is included in your Gemfile")
    end

    it 'should not raise an exception for a dependency file with valid components' do
      main = Volt::AssetFiles.new('/app', 'main', @component_paths)

      path_to_main = File.join(File.dirname(__FILE__), '../../apps/file_loading/app/main')
      path_to_missing_deps = File.join(File.dirname(__FILE__), path_to_main)
      expect do
        main.load_dependencies(path_to_missing_deps, 'component_name')
      end.to_not raise_error
    end

    it 'should parse javascript src/body from the javascript tags' do
      main = Volt::AssetFiles.new('/app', 'main', @component_paths)

      expect(main).to receive(:javascript_tags).and_return("<script src='/someurl.js'></script><script>var inlinejs = true;</script>")

      expect(main.javascript(nil)).to eq([[:src, "/someurl.js"], [:body, "var inlinejs = true;"]])
    end
  end
end
