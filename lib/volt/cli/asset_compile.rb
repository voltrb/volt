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
      ENV['MAPS'] = 'false'

      require 'opal'
      require 'rack'
      require 'volt'
      require 'volt/volt/core'
      require 'volt/boot'
      require 'volt/server'

      @root_path ||= Dir.pwd
      Volt.root  = @root_path

      @volt_app = Volt.boot(@root_path)

      ENV['NO_FORKING'] = 'true'


      require 'volt/server/rack/component_paths'
      require 'volt/server/rack/component_code'

      @app_path = File.expand_path(File.join(@root_path, 'app'))

      # @component_paths   = ComponentPaths.new(@root_path)
      # @app               = Rack::Builder.new
      # @opal_files        = OpalFiles.new(@app, @app_path, @component_paths)
      # @index_files       = IndexFiles.new(@app, @volt_app, @volt_app.component_paths, @volt_app.opal_files)

      # puts 'Compile Opal for components'
      # write_component_js
      # puts 'Copy assets'
      # write_sprockets
      # puts 'Compile JS/CSS'
      # # write_js_and_css
      puts 'Write index files'
      write_index

      puts "A"
      write_files_and_manifest
      puts "B"
      compile_manifests
      puts "C"
      puts "compiled"
    end

    def write_files_and_manifest
      asset_files = AssetFiles.from_cache('main', @volt_app.component_paths)
      # Write a temp css file
      js = asset_files.javascript(@volt_app)
      css = asset_files.css

      # Extract src's and body's
      js_srcs, js_bodys = js.group_by {|v| v[0] }.values
        .map {|v| v.map {|p| p[1] } }

      File.open(Volt.root + '/app/main/app.js', 'wb') do |file|
        js_srcs.each do |src|
          url = src.gsub(/^\/assets\//, '')
          file.write("//= require '#{url}'\n")
        end

        js_bodys.each do |body|
          file.write("#{body}\n")
        end
      end

      File.open(Volt.root + '/app/main/app.scss', 'wb') do |file|
        css.each do |link|
          url = link.gsub(/^\/assets\//, '')
          file.write("//= require '#{url}'\n")
        end
      end
    end

    def compile_manifests
      manifest = Sprockets::Manifest.new(@volt_app.sprockets, './public/assets/manifest.json')

      # Compile the files (and linked assets)
      manifest.compile('main/app.js')
      manifest.compile('main/app.css')

      # Remove the temp files
      FileUtils.rm(Volt.root + '/app/main/app.js')
      FileUtils.rm(Volt.root + '/app/main/app.scss')
    end

    def logical_paths_and_full_paths
      env = @opal_files.environment
      env.each_file do |full_path|
        # logical_path = env[full_path].logical_path
        # logical_path = @opal_files.environment.send(:logical_path_for_filename, full_path, []).to_s
        # puts "FULL PATH: #{full_path.inspect} -- #{logical_path}"

        # yield(logical_path, full_path.to_s)
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
      write_sprocket_file('components/main.js')
    end

    def javascript_tags
      # mtime = File.mtime(Volt.root + '/public/assets/')
      # "<script src=\"/assets/main/app.js?v=#{mtime}\"" />"
    end

    def write_index
      output_path = "#{@root_path}/public/index.html"

      index_path = File.expand_path(File.join(Volt.root, 'config/base/index.html'))
      html       = File.read(index_path)

      ERB.new(html, nil, '-').result(binding)

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
