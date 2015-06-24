# Responsible for setting up all "out of the box" middleware on a Volt app.

require 'rack'
require 'volt/server/rack/keep_alive'
require 'volt/server/rack/quiet_common_logger'
require 'volt/server/rack/opal_files'
require 'volt/server/rack/index_files'
require 'volt/server/rack/http_resource'

module Volt
  class DefaultMiddlewareStack
    # Setup on the middleware we can setup before booting components
    def self.preboot_setup(volt_app, rack_app)
      # Should only be used in production
      if Volt.config.deflate
        rack_app.use Rack::Deflater
        rack_app.use Rack::Chunked
      end

      rack_app.use Rack::ContentLength
      rack_app.use Rack::KeepAlive
      rack_app.use Rack::ConditionalGet
      rack_app.use Rack::ETag

      rack_app.use Rack::Session::Cookie,         key: 'rack.session',
                                                  # :domain => 'localhost.com',
                                                  path: '/',
                                                  expire_after: 2_592_000,
                                                  secret: Volt.config.app_secret

      rack_app.use QuietCommonLogger
      rack_app.use Rack::ShowExceptions
    end

    # Setup the middleware that we need to wait for components to boot before we
    # can set them up.
    def self.postboot_setup(volt_app, rack_app)
      component_paths = volt_app.component_paths
      rack_app.map '/components' do
        run ComponentHandler.new(component_paths)
      end

      # Serve the opal files
      opal_files = OpalFiles.new(rack_app, volt_app.app_path, volt_app.component_paths)
      volt_app.sprockets = opal_files.environment

      # Serve the main html files from public, also figure out
      # which JS/CSS files to serve.
      rack_app.use IndexFiles, volt_app, volt_app.component_paths, opal_files

      rack_app.use HttpResource, volt_app, volt_app.router

      rack_app.use Rack::Static,
                   urls: ['/'],
                   root: 'config/base',
                   index: '',
                   header_rules: [
                     [:all, { 'Cache-Control' => 'public, max-age=86400' }]
                   ]

      rack_app.run ->(env) { [404, { 'Content-Type' => 'text/html; charset=utf-8' }, ['404 - page not found']] }
    end
  end
end
