require 'volt/server/rack/http_response_header'
require 'volt/server/rack/http_response_renderer'
require 'volt/utils/lifecycle_callbacks'

module Volt
  # Allow you to create controllers that act as http endpoints
  class HttpController
    include LifecycleCallbacks

    #TODO params is only public for testing
    attr_accessor :params

    # Setup before_action and after_action
    setup_action_helpers_in_class(:before_action, :after_action)

    # Initialzed with the params parsed from the route and the HttpRequest
    def initialize(volt_app, params, request)
      @volt_app = volt_app
      @response_headers = HttpResponseHeader.new
      @response_body = []
      @request = request
      @params = Volt::Model.new(request.params.symbolize_keys.merge(params), persistor: Volt::Persistors::Params)
    end

    def perform(action='index')
      filtered = run_actions(:before_action, action)
      send(action.to_sym) unless filtered
      run_actions(:after_action, action) unless filtered
      respond
    end

    private

    attr_accessor :response_body
    attr_reader :response_headers, :request

    def store
      @volt_app.page.store
    end

    def head(status, additional_headers = {})
      @response_status = status
      response_headers.merge!(additional_headers)
    end

    def redirect_to(target, status = :found)
      head(status, location: target)
    end

    def render(content)
      status = content.delete(:status) || :ok
      body, additional_headers = HttpResponseRenderer.new.render(content)
      head(status, additional_headers)
      response_body << body
    end

    def respond
      unless @response_status
        # render was not called, show an error
        @response_body = ['Error: render was not called in controller action']
        @response_status = 500
      end

      Rack::Response.new(response_body, response_status, response_headers)
    end

    # Returns the http status code as integer
    def response_status
      if @response_status.is_a?(Symbol)
        Rack::Utils::SYMBOL_TO_STATUS_CODE[@response_status]
      else
        @response_status.try(:to_i) || 200
      end
    end
  end
end
