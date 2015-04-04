require 'volt/server/rack/http_response_header'
require 'volt/server/rack/http_response_renderer'

module Volt
  class HttpController

    attr_accessor :response_body
    attr_reader :params, :response_headers

    def initialize(params, request)
      @response_headers = HttpResponseHeader.new
      @response_body = []
      @request = request
      @params = params.symbolize_keys.merge(request.params)
    end

    def perform(action)
      #TODO: before actions
      self.send(action.to_sym)
      #TODO: after actions / around actions
      respond
    end

    private

    def store
      $page.store
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
      Rack::Response.new(response_body, response_status, response_headers) 
    end

    #Get the http status code as integer
    def response_status
      if @response_status.is_a?(Symbol)
        Rack::Utils::SYMBOL_TO_STATUS_CODE[@response_status]
      else
        @response_status.try(:to_i) || 200
      end
    end

  end
end