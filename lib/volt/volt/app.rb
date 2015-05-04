module Volt
  class App
    attr_reader :component_paths, :router, :page

    def initialize(app_path, additional_paths=[])
      # Setup root path
      Volt.root = app_path

      # Run the app config to load all users config files
      unless RUBY_PLATFORM == 'opal'
        if Volt.server?
          @page = Page.new

          # Setup a global for now
          $page = @page unless defined?($page)
        end
      end

      # Require in app and initializers
      unless RUBY_PLATFORM == 'opal'
        Volt.run_app_and_initializers
      end

      # Load component paths
      @component_paths = ComponentPaths.new(app_path, additional_paths)
      @component_paths.require_in_components(@page || $page)

      unless RUBY_PLATFORM == 'opal'
        setup_router
        require_http_controllers
      end
    end

    unless RUBY_PLATFORM == 'opal'
      def setup_router
        # Find the route file
        home_path  = @component_paths.component_paths('main').first
        routes = File.read("#{home_path}/config/routes.rb")
        @router = Routes.new.define do
          eval(routes)
        end
      end

      def require_http_controllers
        @component_paths.app_folders do |app_folder|
          # Sort so we get consistent load order across platforms
          Dir["#{app_folder}/*/controllers/server/*.rb"].each do |ruby_file|
            #path = ruby_file.gsub(/^#{app_folder}\//, '')[0..-4]
            #require(path)
            require(ruby_file)
          end
        end
      end
    end
  end
end