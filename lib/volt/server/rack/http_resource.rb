require 'rack' if RUBY_PLATFORM != 'opal'
require 'volt'
require 'volt/router/routes'
require 'volt/server/rack/http_request'

module Volt
  # Rack middleware for HttpController
  class HttpResource
    def initialize(app, volt_app, router)
      @app = app
      @volt_app = volt_app
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
      controller = klass.new(@volt_app, params, request)

      # Use the 'meta' thread local to set the user_id for Volt.current_user
      meta_data = {}
      user_id = request.cookies['user_id']
      meta_data['user_id'] = user_id if user_id
      Thread.current['meta'] = meta_data

      controller.perform(action)
    end
  end
end
