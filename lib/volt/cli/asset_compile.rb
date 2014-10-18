module Volt
  class CLI

    desc "precompile", "precompile all application assets"

    def precompile
      compile
    end

    desc "watch", "compiles the project to /compiled when a file changes"

    def watch
      require 'listen'

      listener = Listen.to('app') do |modified, added, removed|
        compile
      end

      listener.start # non-blocking

      Signal.trap("SIGINT") do
        listener.stop
      end

      compile

      begin
        sleep
      rescue ThreadError => e
        # ignore, breaks out on sigint
      end
    end

    private
    def compile
      print "compiling project..."
      require 'fileutils'
      require 'opal'
      require 'volt'
      require 'volt/server/rack/component_paths'
      require 'volt/server/rack/component_code'
      require 'volt/server/rack/opal_files'
      require 'volt/server/rack/index_files'
      require 'volt/server/component_handler'

      @root_path ||= Dir.pwd
      Volt.root  = @root_path

      @app_path = File.expand_path(File.join(@root_path, "app"))

      @component_paths   = ComponentPaths.new(@root_path)
      @app               = Rack::Builder.new
      @opal_files        = OpalFiles.new(@app, @app_path, @component_paths)
      @index_files       = IndexFiles.new(@app, @component_paths, @opal_files)
      @component_handler = ComponentHandler.new(@component_paths)

      write_component_js
      write_sprockets
      write_js_and_css
      write_index

      puts "\rcompiled                             "
    end

    def write_sprockets
      # Serve the opal files
      @opal_files.environment.each_logical_path do |logical_path|
        logical_path = logical_path.to_s
        # Only include files that aren't compiled elsewhere, like fonts
        if !logical_path[/[.](y|css|js|html|erb)$/]
          write_file(logical_path)
        end
      end
    end

    def write_js_and_css
      (@index_files.javascript_files + @index_files.css_files).each do |logical_path|
        logical_path = logical_path.gsub(/^\/assets\//, '')
        write_file(logical_path)
      end

    end

    def write_file(logical_path)
      path = "#{@root_path}/compiled/assets/#{logical_path}"

      FileUtils.mkdir_p(File.dirname(path))

      begin
        content = @opal_files.environment[logical_path].to_s
        File.open(path, "wb") do |file|
          file.write(content)
        end
      rescue Sprockets::FileNotFound, SyntaxError => e
        # ignore
      end
    end

    def write_component_js
      javascript_code = @component_handler.compile_for_component('main')

      components_folder = File.join(Volt.root, '/compiled/components')
      FileUtils.mkdir_p(components_folder)
      File.open(File.join(components_folder, '/main.js'), 'w') do |file|
        file.write(javascript_code)
      end
    end


    def write_index
      path = "#{@root_path}/compiled/index.html"
      FileUtils.mkdir_p(File.dirname(path))

      File.open(path, 'w') do |file|
        file.write(@index_files.html)
      end
    end
  end
end
