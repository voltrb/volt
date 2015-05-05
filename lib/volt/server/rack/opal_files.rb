require 'volt/server/rack/source_map_server'

# There is currently a weird issue with therubyracer
# https://github.com/rails/execjs/issues/15
# https://github.com/middleman/middleman/issues/1367
#
# To get around this, we just force Node for the time being
ENV['EXECJS_RUNTIME'] = 'Node'

# Sets up the maps for the opal assets, and source maps if enabled.
module Volt
  class OpalFiles
    attr_reader :environment

    def initialize(builder, app_path, component_paths)
      Opal::Processor.source_map_enabled = Volt.source_maps?
      Opal::Processor.const_missing_enabled = true

      # Setup Opal paths

      # Add the lib directory to the load path
      Opal.append_path(Volt.root + '/app')
      Opal.append_path(Volt.root + '/lib')

      Gem.loaded_specs.values.each do |gem|
        path = gem.full_gem_path + '/app'

        if Dir.exists?(path)
          Opal.append_path(path)
        end
      end

      # Don't run arity checks in production
      # Opal::Processor.arity_check_enabled = !Volt.env.production?
      # Opal::Processor.dynamic_require_severity = :raise

      server = Opal::Server.new(prefix: '/')

      @component_paths                   = component_paths
      # @environment                       = Opal::Environment.new
      @environment                       = server.sprockets

      # Since the scope changes in builder blocks, we need to capture
      # environment in closure
      environment                        = @environment

      environment.cache = Sprockets::Cache::FileStore.new('./tmp')

      # Compress in production
      if Volt.config.compress_javascript
        require 'uglifier'
        environment.js_compressor  = Sprockets::UglifierCompressor
      end

      if Volt.config.compress_css
        require 'ruby-clean-css'
        require 'ruby-clean-css/sprockets'
        RubyCleanCSS::Sprockets.register(environment)
      end

      server.append_path(app_path)

      volt_gem_lib_path = File.expand_path(File.join(File.dirname(__FILE__), '../../..'))
      server.append_path(volt_gem_lib_path)

      add_asset_folders(server)

      # Add the opal load paths
      Opal.paths.each do |path|
        server.append_path(path)
      end

      builder.map '/assets' do
        run server
      end

      # map server.source_maps.prefix do
      #   run server.source_maps
      # end

      # if Volt.source_maps?
      #   source_maps = SourceMapServer.new(environment)
      #
      #   builder.map(source_maps.prefix) do
      #     run source_maps
      #   end
      # end
    end

    def add_asset_folders(environment)
      @component_paths.asset_folders do |asset_folder|
        environment.append_path(asset_folder)
      end
    end
  end
end
