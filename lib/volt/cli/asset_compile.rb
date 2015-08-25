module Volt
  class CLI
    desc 'precompile', 'precompile all application assets'

    def precompile
      move_to_root
      compile
    end

    private

    def compile
      say "Starting Precompile...", :red
      require 'fileutils'
      ENV['SERVER'] = 'true'
      ENV['MAPS'] = 'false'
      ENV['NO_FORKING'] = 'true'

      if !ENV['VOLT_ENV'] && !ENV['RACK_ENV']
        # Set the default env for compile
        ENV['VOLT_ENV'] = 'production'
      end

      require 'opal'
      require 'rack'
      require 'volt'
      require 'volt/volt/core'
      require 'volt/boot'
      require 'volt/server'
      require 'volt/server/rack/component_paths'
      require 'volt/server/rack/component_code'

      @root_path ||= Dir.pwd
      Volt.root  = @root_path

      @volt_app = Volt.boot(@root_path)

      @app_path = File.expand_path(File.join(@root_path, 'app'))

      say 'Compiling RB, JS, CSS, and Images...', :red
      write_files_and_manifest
      compile_manifests
      say 'Write index files...', :red
      write_index
      say "Done", :green
    end

    def write_files_and_manifest
      asset_files = AssetFiles.from_cache(@volt_app.app_url, 'main', @volt_app.component_paths)
      # Write a temp css file
      js = asset_files.javascript(@volt_app)
      css = asset_files.css
      @tmp_files = []

      File.open(Volt.root + '/app/main/app.js', 'wb') do |file|
        js.each do |type, src_or_body|
          if type == :src
            src = src_or_body
            url = src.gsub(/^#{@volt_app.app_url}\//, '')
            file.write("//= require '#{url}'\n")
          else
            body = src_or_body

            # Write to a tempfile, since sprockets can't mix requires and
            # code.

            require 'securerandom'
            hex = SecureRandom.hex
            tmp_path = Volt.root + "/app/main/__#{hex}.js"
            url = "main/__#{hex}"
            file.write("//= require '#{url}'\n")

            @tmp_files << tmp_path
            File.open(tmp_path, 'wb') {|f| f.write("#{body}\n") }
          end
        end
      end

      File.open(Volt.root + '/app/main/app.scss', 'wb') do |file|
        css.each do |link|
          url = link.gsub(/^#{@volt_app.app_url}\//, '')
          file.write("//= require '#{url}'\n")
        end
      end
    end

    def compile_manifests
      manifest = Sprockets::Manifest.new(@volt_app.sprockets, "./public#{@volt_app.app_url}/manifest.json")

      # Compile the files (and linked assets)
      manifest.compile('main/app.js')
      manifest.compile('main/app.css')

      # Clear temp files
      @tmp_files.each {|path| FileUtils.rm(path) }

      # Remove the temp files
      FileUtils.rm(Volt.root + "#{@volt_app.app_url}/main/app.js")
      FileUtils.rm(Volt.root + "#{@volt_app.app_url}/main/app.scss")
    end

    def write_index
      require 'volt/cli/base_index_renderer'

      output_path = "#{@root_path}/public/index.html"
      require 'json'

      @manifest = JSON.parse(File.read(@root_path + "/public#{@volt_app.app_url}/manifest.json"))
      output_html = BaseIndexRenderer.new(@volt_app, @manifest).html

      write_file(output_path, output_html)
    end

    def write_file(path, data)
      FileUtils.mkdir_p(File.dirname(path))

      File.open(path, 'wb') do |file|
        file.write(data)
      end
    end
  end
end
