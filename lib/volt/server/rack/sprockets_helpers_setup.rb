require 'sprockets-helpers'

module Volt
  class SprocketsHelpersSetup
    def initialize(env)
      @env = env

      setup_path_helpers
      add_linking_in_asset_path
    end

    def setup_path_helpers
      digest = Volt.env.production?

      # Configure Sprockets::Helpers (if necessary)
      Sprockets::Helpers.configure do |config|
        config.environment = @env
        config.prefix      = '/assets'
        config.public_path = 'public'
        config.debug       = false#!Volt.env.production?

        # Force to debug mode in development mode
        # Debug mode automatically sets
        # expand = true, digest = false, manifest = false

        config.digest      = digest

      end

      Sprockets::Helpers.digest = digest

    end

    def add_linking_in_asset_path
      @env.context_class.class_eval do
        # We "freedom-patch" sprockets-helpers asset_path method to
        # automatically link assets.
        def asset_path(source, options = {})
          uri = URI.parse(source)
          return source if uri.absolute?

          options[:prefix] = Sprockets::Helpers.prefix unless options[:prefix]

          if Sprockets::Helpers.debug || options[:debug]
            options[:manifest] = false
            options[:digest] = false
            options[:asset_host] = false
          end

          source_ext = File.extname(source)

          if options[:ext] && source_ext != ".#{options[:ext]}"
            uri.path << ".#{options[:ext]}"
          end

          # Link all assets out of the box
          # Added by volt
          link_asset(uri)

          path = find_asset_path(uri, source, options)
          if options[:expand] && path.respond_to?(:to_a)
            path.to_a
          else
            path.to_s
          end
        end
      end

    end
  end
end