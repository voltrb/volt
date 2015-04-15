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
      params = routes_match?(request)
      if params
        dispatch_to_controller(params, request)
      else
        @app.call env
      end
    end

    private

    def routes_match?(request)
      @router.url_to_params(request.method, request.path)
    end

    # Find the correct controller and call the correct action on it.
    # The controller name and actions need to be set as params for the
    # matching route
    def dispatch_to_controller(params, request)
      namespace = params[:component] || 'main'

      controller_name = params[:controller] + '_controller'
      action = params[:action]

      namespace_module = Object.const_get(namespace.camelize.to_sym)
      klass = namespace_module.const_get(controller_name.camelize.to_sym)
      controller = klass.new(params, request)
      controller.perform(action)
    end
  end
end
