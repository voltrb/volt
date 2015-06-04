module Volt
  class MiddlewareHandler
    def initialize(app, volt_app)
      @app = app
      @volt_app = volt_app

      @volt_app.middleware.set_app(app)
    end

    def call(env)
      @volt_app.middleware.call(env)
    end
  end
end