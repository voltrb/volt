if RUBY_PLATFORM != 'opal'
  require 'volt/server/rack/component_paths'

  describe Volt::ComponentPaths do
    before do
      spec_app_root = File.join(File.dirname(__FILE__), '../../apps/file_loading')

      path_to_main = File.join(File.dirname(__FILE__), '../../apps/file_loading/app/main')
      @component_paths = Volt::ComponentPaths.new(spec_app_root)
    end

    it 'should return the paths to all app folders' do
      match_count = 0
      @component_paths.app_folders do |app_folder|
        if app_folder[/spec\/apps\/file_loading\/app$/] || app_folder[/spec\/apps\/file_loading\/vendor\/app$/]
          match_count += 1
        end
      end

      expect(match_count).to eq(2)
    end

    it 'should return the path to a component' do
      main_path = @component_paths.component_paths('main').first
      expect(main_path).to match(/spec\/apps\/file_loading\/app\/main$/)
    end

    it 'should not return paths to non-volt gems' do
      Gem.loaded_specs['fake-gem'] = Gem::Specification.new do |s|
        s.name = 'fake-gem'
        s.version = Gem::Version.new('1.0')
        s.full_gem_path = '/home/volt/projects/volt-app'
      end
      app_folders = @component_paths.app_folders { |f| f }
      expect(app_folders).to_not include('/home/volt/projects/volt-app/app')
      Gem.loaded_specs.delete 'fake-gem'
    end
  end
end
