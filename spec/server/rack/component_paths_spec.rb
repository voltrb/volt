if RUBY_PLATFORM != 'opal'
  require 'volt/server/rack/component_paths'

  describe Volt::ComponentPaths do
    before do
      spec_app_root = File.join(__dir__, '../../apps/file_loading')

      path_to_main = File.join(__dir__, '../../apps/file_loading/app/main')
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
  end
end
