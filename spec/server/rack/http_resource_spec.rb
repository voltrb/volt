if RUBY_PLATFORM != 'opal'
  require 'volt/server/rack/http_resource'
  require 'volt/controllers/http_controller'
  require 'volt/server/rack/http_request'
  require 'volt/router/routes'

  describe Volt::HttpResource do
    def routes(&block)
      @routes = Volt::Routes.new
      @routes.define(&block)
    end

    class SimpleController < Volt::HttpController
      attr_reader :action_called

      def index
        @action_called = true
        render text: 'just some text'
      end

      def show
        render text: "show with id #{params._stuff_id} " \
                      "and #{params._test} called"
      end
    end

    let(:app) { ->(env) { [404, env, 'app'] } }

    before(:each) do
      routes do
        get '/stuff', controller: 'simple', action: 'index'
        get '/stuff/{{ stuff_id }}', controller: 'simple', action: 'show'
      end
    end

    it 'should initialize the correct controller and call the correct action' do
      http_resource = Volt::HttpResource.new(app, volt_app, @routes)
      env = Rack::MockRequest.env_for('http://example.com/stuff')
      request = Volt::HttpRequest.new(env)
      controller = SimpleController.new(volt_app, {}, request)
      expect(SimpleController).to receive(:new).and_return(controller)

      response = http_resource.call(env)
      expect(response.status).to eq(200)
      expect(response.body).to eq(['just some text'])
      expect(controller.action_called).to eq(true)
    end

    it 'should parse the correct params to the controller' do
      http_resource = Volt::HttpResource.new(app, volt_app, @routes)
      env = Rack::MockRequest.env_for('http://example.com/stuff/99?test=another_param')
      request = Volt::HttpRequest.new(env)

      response = http_resource.call(env)
      expect(response.status).to eq(200)
      expect(response.body).to eq(['show with id 99 and another_param called'])
    end

    it 'should call the supplied app if routes are not matched and cause a 404' do
      http_resource = Volt::HttpResource.new(app, volt_app, @routes)
      env = Rack::MockRequest.env_for('http://example.com/not_a_valid_param')
      request = Volt::HttpRequest.new(env)
      response = http_resource.call(env)
      expect(response[0]).to eq(404)
      #expect(response.body).to eq(['show with id 99 and another_param called'])
    end

  end
end
