require 'spec_helper'

if RUBY_PLATFORM != 'opal'
  require 'volt/controllers/http_controller'
  require 'volt/server/rack/http_request'
  require 'volt/server/rack/http_resource'

  describe Volt::HttpController do
    class TestHttpController < Volt::HttpController
      attr_reader :ran_action1
      attr_reader :action_called
      attr_reader :stoped_action_called

      before_action :run_action1
      before_action :run_action2, only: [:stoped_action]

      def just_call_an_action
        @action_called = true
      end

      def ok_head_action
        head :ok, location: 'http://example.com'
      end

      def created_head_action
        head :created
      end

      def head_with_http_headers
        head :ok, location: 'http://path.to/example'
      end

      def redirect_action
        redirect_to 'http://path.to/example'
      end

      def render_plain_text
        render text: 'just plain text'
      end

      def render_json
        render json: { 'this' => 'is_json', 'another' => 'pair' }
      end

      def render_json_with_custom_headers
        render json: { some: 'json' },
               status: :created, location: '/test/location'
      end

      def access_body
        render json: JSON.parse(request.body.read)
      end

      def stoped_action
        @stoped_action_called = true
      end

      def run_action1
        @ran_action1 = true
      end

      def run_action2
        stop_chain
      end
    end

    let(:app) { ->(env) { [404, env, 'app'] } }

    let(:request) do
      Volt::HttpRequest.new(
        Rack::MockRequest.env_for('http://example.com/test.html',
                                  'CONTENT_TYPE' => 'text/plain;charset=utf-8'))
    end

    let(:controller) { TestHttpController.new(volt_app, {}, request) }

    it 'should merge the request params and the url params' do
      request = Volt::HttpRequest.new(
        Rack::MockRequest.env_for('http://example.com/test.html?this=is_a&test=param'))
      controller = TestHttpController.new(
        volt_app, { another: 'params', 'and_a' => 'string' }, request)
      expect(controller.params.size).to eq(4)
      expect(controller.params._and_a).to eq('string')
      expect(controller.params._this).to eq('is_a')
    end

    it 'should perform the correct action' do
      expect(controller.action_called).not_to be(true)
      controller.perform(:just_call_an_action)
      expect(controller.action_called).to be(true)
    end

    it 'should redirect' do
      expect(controller.action_called).not_to be(true)
      response = controller.perform(:redirect_action)
      expect(response.location).to eq('http://path.to/example')
      expect(response.status).to eq(302)
    end

    it 'should respond with head' do
      response = controller.perform(:ok_head_action)
      expect(response.status).to eq(200)
      expect(response.body).to eq([])

      response = controller.perform(:created_head_action)
      expect(response.status).to eq(201)

      response = controller.perform(:head_with_http_headers)
      expect(response.headers['Location']).to eq('http://path.to/example')
      expect(response.location).to eq('http://path.to/example')
    end

    it 'should render plain text' do
      response = controller.perform(:render_plain_text)
      expect(response.status).to eq(200)
      expect(response['Content-Type']).to eq('text/plain')
      expect(response.body).to eq(['just plain text'])
    end

    it 'should render json' do
      response = controller.perform(:render_json)
      expect(response.status).to eq(200)
      expect(response['Content-Type']).to eq('application/json')
      expect(JSON.parse(response.body.first)).to eq('this' => 'is_json',
                                                    'another' => 'pair')
    end

    it 'should set the correct status for rendered responses' do
      response = controller.perform(:render_json_with_custom_headers)
      expect(response.status).to eq(201)
    end

    it 'should include the custum headers' do
      response = controller.perform(:render_json_with_custom_headers)
      expect(response['Location']).to eq('/test/location')
    end

    it 'should have access to the body' do
      http_app = Volt::HttpResource.new(app, volt_app, nil)
      allow(http_app).to receive(:routes_match?)
        .and_return(controller: 'test_http',
                    action: 'access_body')
      request = Rack::MockRequest.new(http_app)
      response = request.post('http://example.com/test.html', input:
        { test: 'params' }.to_json)
      expect(response.body).to eq({ test: 'params' }.to_json)
    end

    it 'should run the before action' do
      controller.perform(:render_plain_text)
      expect(controller.ran_action1).to be(true)
    end

    it 'should not call the stoped_action' do
      controller.perform(:stoped_action)
      expect(controller.stoped_action_called).to be_nil
    end
  end
end
