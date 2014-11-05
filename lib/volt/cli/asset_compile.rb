module Volt
  class CLI
    desc 'precompile', 'precompile all application assets'

    def precompile
      compile
    end

    private

    def compile
      print 'compiling project...'
      require 'fileutils'
      ENV['SERVER'] = 'true'

      require 'opal'
      require 'volt'
      require 'volt/boot'

      Volt.boot(Dir.pwd)

      require 'volt/server/rack/component_paths'
      require 'volt/server/rack/component_code'
      require 'volt/server/rack/opal_files'
      require 'volt/server/rack/index_files'
      require 'volt/server/component_handler'

      @root_path ||= Dir.pwd
      Volt.root  = @root_path

      @app_path = File.expand_path(File.join(@root_path, 'app'))

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
        unless logical_path[/[.](y|css|js|html|erb)$/]
          write_sprocket_file(logical_path)
        end
      end
    end

    def write_js_and_css
      (@index_files.javascript_files + @index_files.css_files).each do |logical_path|
        if logical_path =~ /^\/assets\//
          logical_path = logical_path.gsub(/^\/assets\//, '')
          write_sprocket_file(logical_path)
        end
      end
    end

    def write_sprocket_file(logical_path)
      path = "#{@root_path}/public/assets/#{logical_path}"

      begin
        content = @opal_files.environment[logical_path].to_s
        write_file(path, content)
      rescue Sprockets::FileNotFound, SyntaxError => e
        # ignore
      end
    end

    def write_component_js
      javascript_code = @component_handler.compile_for_component('main')

      path = File.join(Volt.root, '/public/components/main.js')
      write_file(path, javascript_code)
    end

    def write_index
      path = "#{@root_path}/public/index.html"

      write_file(path, @index_files.html)
    end

    def write_file(path, data)
      FileUtils.mkdir_p(File.dirname(path))

      File.open(path, 'wb') do |file|
        file.write(data)
      end
    end
  end
end
