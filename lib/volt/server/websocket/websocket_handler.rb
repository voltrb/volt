require 'faye/websocket'
require 'volt/server/socket_connection_handler'

# Load websocket options once at boot
# The ENV['DYNO'] option lets it kick in automatically if we're on heroku.
WEBSOCKET_OPTIONS = if !ENV['NO_WEBSOCKET_PING'] &&
  (ENV['WEBSOCKET_PING_TIME'] || ENV['DYNO'])
  {ping: (ENV['WEBSOCKET_PING_TIME'] || 30).to_i}
else
  {}
end

module Volt
  class WebsocketHandler
    def initialize(app)
      @app = app
    end

    def call(env)
      if Faye::WebSocket.websocket?(env)
        ws = Faye::WebSocket.new(env, nil, WEBSOCKET_OPTIONS)

        socket_connection_handler = SocketConnectionHandler.new(ws)

        ws.on :message do |event|
          socket_connection_handler.process_message(event.data)
        end

        ws.on :close do |event|
          socket_connection_handler.closed

          ws = nil
        end

        # Return async Rack response
        ws.rack_response
      else
        # Call down to the app
        @app.call(env)
      end
    end
  end
end
