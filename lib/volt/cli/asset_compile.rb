class CLI

  desc "precompile", "precompile all application assets"
  def precompile
    require 'fileutils'
    require 'opal'
    require 'volt'
    require 'volt/server/rack/component_paths'
    require 'volt/server/rack/component_code'
    require 'volt/server/rack/opal_files'


    write_component_js
    write_sprockets
  end

  private
    def write_sprockets
      root_path ||= Dir.pwd
      Volt.root = root_path

      @app_path = File.expand_path(File.join(root_path, "app"))

      @component_paths = ComponentPaths.new(root_path)
      @app = Rack::Builder.new

      # Serve the opal files
      opal_files = OpalFiles.new(@app, @app_path, @component_paths)
      opal_files.environment.each_file do |file_path|
        unless file_path.to_s[/[.]rb$/]
          puts "FILE: #{file_path}"
        end
      end
    end

    def write_component_js
      component_paths = ComponentPaths.new(Volt.root)

      code = ComponentCode.new('home', component_paths).code

      javascript_code = Opal.compile(code)

      components_folder = File.join(Volt.root, '/public/components')
      puts "CF: #{components_folder}"
      FileUtils.mkdir_p(components_folder)
      File.open(File.join(components_folder, '/home.js'), 'w') do |file|
        file.write(javascript_code)
      end
    end

end