module Rack
  # TODO: For some reason in Rack (or maybe thin), 304 headers close
  # the http connection.  We might need to make this check if keep
  # alive was in the request.
  class KeepAlive
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)

      if status == 304 && env['HTTP_CONNECTION'] && env['HTTP_CONNECTION'].downcase == 'keep-alive'
        headers['Connection'] = 'keep-alive'
      end

      [status, headers, body]
    end
  end
end