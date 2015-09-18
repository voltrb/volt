require 'volt/server/rack/asset_files'
require 'volt/router/routes'

# Serves the main pages
module Volt
  class IndexFiles
    def initialize(rack_app, volt_app, component_paths, opal_files)
      @rack_app        = rack_app
      @volt_app        = volt_app
      @component_paths = component_paths
      @opal_files      = opal_files

      @@router = volt_app.router
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
        @rack_app.call env
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
      AssetFiles.from_cache(@volt_app.app_url, 'main', @component_paths).javascript_tags(@volt_app)
    end

    def css_tags
      AssetFiles.from_cache(@volt_app.app_url, 'main', @component_paths).css_tags
    end
  end
end
