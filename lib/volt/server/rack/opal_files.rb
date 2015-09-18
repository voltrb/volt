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
    attr_reader :environment, :server

    def initialize(builder, app_url, app_path, component_paths)
      Opal::Processor.source_map_enabled = Volt.source_maps?
      Opal::Processor.const_missing_enabled = true

      # Setup Opal paths

      # Add the lib directory to the load path
      Opal.append_path(Volt.root + '/app')

      Gem.loaded_specs.values.select {|gem| gem.name =~ /^(volt|ejson_ext)/ }
      .each do |gem|
        ['app', 'lib'].each do |folder|
          path = gem.full_gem_path + "/#{folder}"

          Opal.append_path(path) if Dir.exist?(path)
        end
      end

      # Don't run arity checks in production
      # Opal::Processor.arity_check_enabled = !Volt.env.production?
      # Opal::Processor.dynamic_require_severity = :raise

      @server = Opal::Server.new(prefix: app_url, debug: Volt.source_maps?)
      @server.use_index = false

      @component_paths                   = component_paths
      # @environment                       = Opal::Environment.new
      @environment                       = @server.sprockets

      environment.cache = Sprockets::Cache::FileStore.new('./tmp')

      # Compress in production
      if Volt.config.compress_javascript
        require 'uglifier'
        environment.js_compressor  = Sprockets::UglifierCompressor
      end

      if Volt.config.compress_css
        # Use csso for css compression by default.
        require 'csso'
        require 'volt/utils/csso_patch'
        Csso.install(environment)
      end

      if Volt.config.compress_images
        add_image_compression
      end

      @server.append_path(app_path)

      volt_gem_lib_path = File.expand_path(File.join(File.dirname(__FILE__), '../../..'))
      @server.append_path(volt_gem_lib_path)

      add_asset_folders(@server)


      # Setup ViewProcessor to parse views
      Volt::ViewProcessor.setup(@environment)

      # Use the cached env in production so it doesn't have to stat the FS
      if Volt.env.production?
        @environment = @environment.cached
        @server.sprockets = @environment
      end

      # Since the scope changes in builder blocks, we need to capture
      # environment in closure
      environment                        = @environment

      builder.map(app_url) do
        run environment
      end

      # Remove dup paths
      Opal.paths.uniq!

      @environment.logger.level ||= Logger::DEBUG
      source_map_enabled = Volt.source_maps?
      if source_map_enabled
        maps_prefix = Opal::Server::SOURCE_MAPS_PREFIX_PATH
        maps_app = Opal::SourceMapServer.new(@environment, maps_prefix)
        ::Opal::Sprockets::SourceMapHeaderPatch.inject!(maps_prefix)
      end

      if source_map_enabled
        builder.map(maps_prefix) do
          require 'rack/conditionalget'
          require 'rack/etag'
          use Rack::ConditionalGet
          use Rack::ETag
          run maps_app
        end
      end
    end

    def add_image_compression
      if defined?(ImageOptim)
        env = @environment
        image_optim = ImageOptim.new({pngout: false, svgo: false})

        processor = proc do |_context, data|
          image_optim.optimize_image_data(data) || data
        end

        env.register_preprocessor 'image/gif', :image_optim, &processor
        env.register_preprocessor 'image/jpeg', :image_optim, &processor
        env.register_preprocessor 'image/png', :image_optim, &processor
        env.register_preprocessor 'image/svg+xml', :image_optim, &processor
      end
    end

    def add_asset_folders(environment)
      # @component_paths.asset_folders do |asset_folder|
      #   puts "ADD ASSET FOLDER: #{asset_folder.inspect}"
      #   environment.append_path(asset_folder)
      # end
    end
  end
end
