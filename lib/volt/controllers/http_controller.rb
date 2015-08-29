require 'volt/server/rack/http_response_header'
require 'volt/server/rack/http_response_renderer'
require 'volt/controllers/http_controller/http_cookie_persistor'
require 'volt/controllers/login_as_helper'
require 'volt/utils/lifecycle_callbacks'

module Volt
  # Allow you to create controllers that act as http endpoints
  class HttpController
    include LifecycleCallbacks
    include LoginAsHelper

    # Setup before_action and after_action
    setup_action_helpers_in_class(:before_action, :after_action)

    # Initialzed with the params parsed from the route and the HttpRequest
    def initialize(volt_app, params, request)
      @volt_app = volt_app
      @response_headers = HttpResponseHeader.new
      @response_body = []
      @request = request
      @initial_params = params
    end

    def params
      @params ||= begin
        params = request.params.symbolize_keys.merge(@initial_params)
        Volt::Model.new(params, persistor: Volt::Persistors::Params)
      end
    end

    def cookies
      @cookies ||= Volt::Model.new(request.cookies, persistor: Volt::Persistors::HttpCookiePersistor)
    end

    def perform(action='index')
      filtered = run_callbacks(:before_action, action)
      send(action.to_sym) unless filtered
      run_callbacks(:after_action, action) unless filtered
      respond
    end

    private

    attr_accessor :response_body
    attr_reader :response_headers, :request

    def store
      @volt_app.store
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

      resp = Rack::Response.new(response_body, response_status, response_headers)

      # Update any changed cookies
      new_cookies = cookies.persistor.changed_cookies

      new_cookies.each_pair do |key, value|
        if value.is_a?(String)
          value = {value: value}
        end
        value[:path] = '/'

        resp.set_cookie(key.to_s, value)
      end

      resp
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
