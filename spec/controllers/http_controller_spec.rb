if RUBY_PLATFORM != 'opal'
  require 'volt/controllers/http_controller'
  require 'volt/server/rack/http_request'

  describe Volt::HttpController do

    class TestHttpController < Volt::HttpController

      attr_reader :action_called

      def just_call_an_action
        @action_called = true
      end

      def ok_head_action
        head :ok, location: "http://example.com"
      end

      def created_head_action
        head :created
      end

      def head_with_http_headers
        head :ok, location: "http://path.to/example"
      end

      def redirect_action
        redirect_to "http://path.to/example"
      end

      def render_plain_text
        render plain: "just plain text"
      end

      def render_json
        render json: { "this" => "is_json", "another" => "pair" }
      end

      def render_json_with_custom_headers
        render json: { some: "json" }, status: :created, location: "/test/location"
      end

    end

    let(:request) {
      Volt::HttpRequest.new(Rack::MockRequest.env_for("http://example.com/test.html", "CONTENT_TYPE" => "text/plain;charset=utf-8"))
    }

    let(:controller) {
      TestHttpController.new({}, request)
    }

    it "should merge the request params and the url params" do
      request = Volt::HttpRequest.new(
        Rack::MockRequest.env_for("http://example.com/test.html?this=is_a&test=param"))
      controller = TestHttpController.new({another: 'params', "and_a" => "string"}, request)
      expect(controller.params.size).to eq(4)
      expect(controller.params[:and_a]).to eq("string")
      expect(controller.params[:this]).to eq('is_a')
    end

    it "should perform the correct action" do
      expect(controller.action_called).not_to be(true)
      controller.perform(:just_call_an_action)
      expect(controller.action_called).to be(true)
    end

    it "should redirect" do
      expect(controller.action_called).not_to be(true)
      response = controller.perform(:redirect_action)
      expect(response.location).to eq("http://path.to/example")
      expect(response.status).to eq(302)
    end

    it "should respond with head" do
      response = controller.perform(:ok_head_action)
      expect(response.status).to eq(200)
      expect(response.body).to eq([])

      response = controller.perform(:created_head_action)
      expect(response.status).to eq(201)

      response = controller.perform(:head_with_http_headers)
      expect(response.headers['Location']).to eq('http://path.to/example')
      expect(response.location).to eq('http://path.to/example')
    end

    it "should render plain text" do
      response = controller.perform(:render_plain_text)
      expect(response.status).to eq(200)      
      expect(response['Content-Type']).to eq("text/plain")
      expect(response.body).to eq(["just plain text"])
    end

    it "should render json" do
      response = controller.perform(:render_json)
      expect(response.status).to eq(200)      
      expect(response['Content-Type']).to eq("application/json")
      expect(JSON.parse(response.body.first)).to eq({ "this" => "is_json", "another" => "pair" })
    end

    it "should set the correct status for rendered responses" do
      response = controller.perform(:render_json_with_custom_headers)
      expect(response.status).to eq(201)
    end

    it "should include the custum headers" do
      response = controller.perform(:render_json_with_custom_headers)
      expect(response['Location']).to eq('/test/location')
    end
  end
end