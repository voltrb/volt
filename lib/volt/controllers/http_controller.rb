module Volt
  class HttpController

    attr_accessor :response_body, :response_headers

    def initialize(request)
      @response_headers = {}
      @response_body = []
      @request = request
    end

    def perform(action)
      #before actions
      self.send(action.to_sym)
      #after action
      respond
    end

    private

    def redirect_to(target, status = :found)
      response_headers['Location'] = target
      @response_status = status
    end

    def render(val, status = :ok)
      response_body << val
      response_headers['Content-Type'] = "text/plain"
      @response_status = status
    end

    def head(status, options = {})
      
    end

    def respond
      Rack::Response.new(response_body, response_status, response_headers) do |response|
        unless has_content?
          response_headers.delete('Content-Type')
          response_headers.delete('Content-Length')
        end
      end
    end

    #Get the http status code as integer
    def response_status
      if @response_status.is_a?(Symbol)
        Rack::Utils::SYMBOL_TO_STATUS_CODE[@response_status]
      else
        @response_status.try(:to_i) || 200
      end
    end

    #Current status code has content?
    def has_content?
      case response_status
      when 100..199
        false
      when 204, 205, 304
        false
      else
        true
      end
    end  
  end
end