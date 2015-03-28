require 'rack'
require 'volt'
require 'volt/router/routes'
require 'volt/server/rack/http_request'

module Volt
  # Rack middleware for HttpController
  class HttpResource
    def initialize(app, router)
      @app = app
      @router = router
    end

    def call(env)
      request = HttpRequest.new(env)
      if params = routes_match?(request)
        dispatch_to_controller(params, request)
      else
        @app.call env
      end
    end

    private

    def routes_match?(request)
      @router.url_to_params(request.method, request.path)
    end

    def dispatch_to_controller(params, request)
      controller_name = params[:_controller] + "_controller"
      action = params[:_action]
      controller = Object.const_get(controller_name.camelize.to_sym).new(params, request)
      controller.perform(action)
    end
  end
end
