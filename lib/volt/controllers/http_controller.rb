require 'volt/server/rack/http_resonse_header'

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
      #TODO before actions
      self.send(action.to_sym)
      #TODO after actions / around actions
      respond
    end

    private

    def redirect_to(target, status = :found)
      response_headers[:location] = target
      @response_status = status
    end

    def head(status, options = {})
      @response_status = status
      response_headers.merge!(options)
    end

    def render(val)
      # val[:status] = :ok unless val[:status]
      # renderer = Renderer.for(val)
      response_body << val[:plain]
      #response_headers = response_headers.merge(renderer.headers)      
      response_headers['Content-Type'] = "text/plain"
      @response_status = :ok
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