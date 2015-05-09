require 'volt'
require 'rack' if RUBY_PLATFORM != 'opal'

module Volt
  # A request object for a HttpController. See Rack::Request for more details
  class HttpRequest < Rack::Request
    # Returns the request format
    # /acticles/index.html => html
    # Defaults to the media_type of the request
    def format
      path_format || media_type
    end

    # Returns the path_info without the format
    # /blub/index.html => /blub/index
    def path
      path_format ? path_info[0..path_format.size * -1 - 2] : path_info
    end

    # Returns the request method
    # Allows requests to override the http request method by setting _method
    def method
      if params[:_method]
        params[:_method].to_s.downcase.to_sym
      else
        request_method.downcase.to_sym
      end
    end

    # The request params with symbolized keys
    def params
      super.symbolize_keys
    end

    private

    # Returns the format given in the path_info
    # http://example.com/test.html => html
    # http://example.com/test => nil
    def path_format
      @path_format ||= extract_format_from_path
    end

    # Extract from the path
    def extract_format_from_path
      format = path_info.match(/\.(\w+)$/)
      format.present? ? format[1] : nil
    end
  end
end
