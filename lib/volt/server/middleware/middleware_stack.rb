# Volt::MiddlewareStack provides an interface where app code can add custom
# rack middleware.  Volt.current_app.middleware returns an instance of
# Volt::MiddlewareStack, and apps can call #use to add in more middleware.

module Volt
  class MiddlewareStack
    attr_reader :middlewares

    def initialize
      # Setup the next app
      @middlewares = []
    end

    def use(*args, &block)
      @middlewares << [args, block]

      # invalidate builder, so it gets built again
      @builder = nil
    end

    def map(path, &block)
      @middlewares << [:map, path, block]

      # invalidate builder
      @builder = nil
    end

    def run(app)
      @app = app
    end

    # Builds a new Rack::Builder with the middleware and the app
    def build
      @builder = Rack::Builder.new

      @middlewares.each do |middleware|
        if middleware[0] == :map
          @builder.map(middleware[1], &middleware[2])
        else
          @builder.use(*middleware[0], &middleware[1])
        end
      end

      @builder.run(@app)
    end

    def call(env)
      unless @builder
        build
      end

      @builder.call(env)
    end
  end
end