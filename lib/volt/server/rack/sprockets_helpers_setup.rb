require 'sprockets-helpers'

module Volt
  class SprocketsHelpersSetup
    def initialize(volt_app)
      @volt_app = volt_app
      @env = volt_app.sprockets

      setup_path_helpers
      add_linking_in_asset_path
    end

    def setup_path_helpers
      digest = Volt.env.production?

      # Configure Sprockets::Helpers (if necessary)
      Sprockets::Helpers.configure do |config|
        config.environment = @env
        config.prefix      = @volt_app.app_url
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
      app_path = @volt_app.app_path
      @env.context_class.class_eval do
        # We "freedom-patch" sprockets-helpers asset_path method to
        # automatically link assets.
        define_method(:asset_path) do |source, options = {}|
          relative_path = source =~ /^[.][.]\//
          if relative_path
            component_root = logical_path.gsub(/\/[^\/]+$/, '')
            path = File.join(component_root, source)
            source = Volt::SprocketsHelpersSetup.expand(path)
          end

          if relative_path
            link_path = source
          else
            link_path = source.gsub(/^#{app_path}\//, '')
          end

          # Return for absolute urls (one's off site)
          uri = URI.parse(source)
          return source if uri.absolute?

          # Link all assets out of the box
          # Added by volt
          link_asset(link_path)

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

          path = find_asset_path(uri, source, options)

          if options[:expand] && path.respond_to?(:to_a)
            path.to_a
          else
            path.to_s
          end
        end
      end

    end

    private

    def self.expand(path)
      parts = path.split('/')

      output = []

      parts.each do |part|
        if part == '..'
          output.pop
        else
          output << part
        end
      end

      output.join('/')
    end
  end
end