require 'volt'
require 'volt/router/routes'
require 'rack'

module Volt
  # Rack middleware for HttpController
  class HttpResource
    def initialize(app)
      @app = app
      #@@router ||= Routes.new.define do
        # Find the route file
        #home_path  = component_paths.component_paths('main').first
        #route_file = File.read("#{home_path}/config/routes.rb")
        #eval(route_file)
      #end
    end

    def call(env)
      path = env['PATH_INFO']
      if controller_name = routes_match?(path)
        controller = Object.const_get(controller_name.camelize.to_sym).new
        controller.perform(:index)
      else
        @app.call env
      end
    end

    private

    def routes_match?(path)
      matched = path.match(/^\/http_controller_test\/(.+)/)
      matched.present? ? matched[1] : false
    end
  end
end
