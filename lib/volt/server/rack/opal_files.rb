require 'volt/server/rack/source_map_server'
if Volt.env.production?
  # Compress assets in production
  require 'uglifier'
end

# Sets up the maps for the opal assets, and source maps if enabled.
module Volt
  class OpalFiles
    attr_reader :environment

    def initialize(builder, app_path, component_paths)
      Opal::Processor.source_map_enabled = Volt.source_maps?
      Opal::Processor.const_missing_enabled = true

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

      if Volt.env.production?
        # Compress in production
        environment.js_compressor  = Sprockets::UglifierCompressor
        environment.css_compressor = Sprockets::YUICompressor
      end

      server.append_path(app_path)

      volt_gem_lib_path = File.expand_path(File.join(File.dirname(__FILE__), '../../..'))
      server.append_path(volt_gem_lib_path)

      add_asset_folders(server)

      # Add the opal load paths
      Opal.paths.each do |path|
        server.append_path(path)
      end

      # opal-jquery gem
      spec = Gem::Specification.find_by_name('opal-jquery')
      server.append_path(spec.gem_dir + '/lib')

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
