# Middleware for parsing params of different restful content in HTTP endpoints.
# Content-type: application/json - is supported out of the box
#
# Much thanks to @achiu (https://github.com/achiu) for original version of this middleware
#
# New Parsers can be added in your app's config:
#      Volt.setup do |config|
#        config.http_content_types = {
#          parsers: {
#            'application/roll' => proc { |body| {'rick_says' => 'never gonna give you up'}}
#          }
#        }
#      end

module Rack
  class HttpContentTypes

    POST_BODY  = 'rack.input'.freeze
    FORM_INPUT = 'rack.request.form_input'.freeze
    FORM_HASH  = 'rack.request.form_hash'.freeze

    JSON_PARSER   = proc { |data| JSON.parse data }
    ERROR_HANDLER = proc { |err, type| [400, {}, ['']] }

    attr_reader :parsers, :handlers, :logger

    def initialize(app, options = {})
      @app = app
      @options = Volt.config.http_content_types.dup || {}
      @options.merge!(options)
      @parsers = @options[:parsers] || {}
      @handlers = @options[:handlers] || {}
      unless parsers.detect { |content_type, _| 'json'.match(content_type) }
        @parsers.merge!({ %r{json} => JSON_PARSER })
      end
    end

    def call(env)
      type   = Rack::Request.new(env).media_type
      parser = parsers.detect { |content_type, _| type.match(content_type) } if type
      return @app.call(env) unless parser
      body = env[POST_BODY].read ; env[POST_BODY].rewind
      return @app.call(env) unless body && !body.empty?
      begin
        parsed = parser.last.call body
        env.update FORM_HASH => parsed, FORM_INPUT => env[POST_BODY]
      rescue StandardError => e
        warn! e, type
        handler   = handlers.detect { |content_type, _|  type.match(content_type) }
        handler ||= ['default', ERROR_HANDLER]
        return handler.last.call(e, type)
      end
      @app.call env
    end

    def warn!(error, content_type)
      return unless Volt.logger
      message = "[Rack::HttpContentType] Error on %s : %s" % [content_type, error.to_s]
      Volt.logger.warn message
    end
  end
end
