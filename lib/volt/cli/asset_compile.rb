module Volt
  class CLI
    desc 'precompile', 'precompile all application assets'

    def precompile
      compile
    end

    private

    def compile
      puts 'compiling project...'
      require 'fileutils'
      ENV['SERVER'] = 'true'

      require 'opal'
      require 'rack'
      require 'volt'
      require 'volt/volt/core'
      require 'volt/boot'

      @root_path ||= Dir.pwd
      Volt.root  = @root_path

      volt_app = Volt.boot(@root_path)

      require 'volt/server/rack/component_paths'
      require 'volt/server/rack/component_code'
      require 'volt/server/rack/opal_files'
      require 'volt/server/rack/index_files'
      require 'volt/server/component_handler'

      @app_path = File.expand_path(File.join(@root_path, 'app'))

      @component_paths   = ComponentPaths.new(@root_path)
      @app               = Rack::Builder.new
      @opal_files        = OpalFiles.new(@app, @app_path, @component_paths)
      @index_files       = IndexFiles.new(@app, volt_app, @component_paths, @opal_files)
      @component_handler = ComponentHandler.new(@component_paths)

      puts 'Compile Opal for components'
      write_component_js
      puts 'Copy assets'
      write_sprockets
      puts 'Compile JS/CSS'
      write_js_and_css
      puts 'Write index files'
      write_index

      puts "compiled"
    end

    def logical_paths_and_full_paths
      @opal_files.environment.each_file do |full_path|
        logical_path = @opal_files.environment.send(:logical_path_for_filename, full_path, []).to_s

        yield(logical_path, full_path.to_s)
      end

    end

    def write_sprockets
      # Serve the opal files
      logical_paths_and_full_paths do |logical_path, full_path|
        # Only include files that aren't compiled elsewhere, like fonts
        if !logical_path[/[.](y|css|js|html|erb)$/] &&
          File.extname(logical_path) != '' &&
          # opal includes some node modules in the standard lib that we don't need to compile in
          (full_path !~ /\/opal/ && full_path !~ /\/stdlib\// && logical_path !~ /^node_js\//)
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
        # Only write out the assets
        # if logical_path =~ /\/assets\//
          content = @opal_files.environment[logical_path].to_s
          write_file(path, content)
        # end
      rescue Sprockets::FileNotFound, SyntaxError => e
        # ignore
      end
    end

    def write_component_js
      javascript_code = @component_handler.compile_for_component('main', true)

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
