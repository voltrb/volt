require 'volt/server/rack/asset_files'
require 'volt/router/routes'

# Serves the main pages
module Volt
  class IndexFiles
    def initialize(app, volt_app, component_paths, opal_files)
      @app             = app
      @volt_app        = volt_app
      @component_paths = component_paths
      @opal_files      = opal_files

      @@router = volt_app.router

      @@router.define do
        # Load routes for each component
        component_paths.components.values.flatten.uniq.each do |component_path|
          routes_path = "#{component_path}/config/routes.rb"

          if File.exist?(routes_path)
            route_file = File.read(routes_path)
            instance_eval(route_file, routes_path, 0)
          end
        end
      end
    end

    def route_match?(path)
      params = @@router.url_to_params(path)

      return params if params

      false
    end

    def call(env)
      if route_match?(env['PATH_INFO'])
        [200, { 'Content-Type' => 'text/html; charset=utf-8' }, [html]]
      else
        @app.call env
      end
    end

    def html
      index_path = File.expand_path(File.join(Volt.root, 'config/base/index.html'))
      html       = File.read(index_path)

      ERB.new(html, nil, '-').result(binding)
    end

    def javascript_files(*args)
      fail "Deprecation: #javascript_files is deprecated in config/base/index.html, opal 0.8 required a new format."
    end

    def css_files(*args)
      fail "Deprecation: #css_files is deprecated in config/base/index.html, opal 0.8 required a new format."
    end

    def javascript_tags
      # TODO: Cache somehow, this is being loaded every time
      AssetFiles.new('main', @component_paths).javascript_tags(@volt_app)
    end

    def css_tags
      AssetFiles.new('main', @component_paths).css_tags
    end
  end
end
