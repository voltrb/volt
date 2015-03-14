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

		def redirect_action
			redirect_to "http://path.to/example"
		end

		def render_action
			render "just plain text"
		end
	end

	let(:request) {
		Volt::HttpRequest.new(Rack::MockRequest.env_for("http://example.com/test.html", "CONTENT_TYPE" => "text/plain;charset=utf-8"))
	}

  it "should perform the correct action" do
  	controller = TestHttpController.new(request)
	 	expect(controller.action_called).not_to be(true)
  	controller.perform(:just_call_an_action)
  	expect(controller.action_called).to be(true)
  end

  it "should redirect" do
  	controller = TestHttpController.new(request)
	 	expect(controller.action_called).not_to be(true)
  	response = controller.perform(:redirect_action)
  	expect(response.redirect?).to be(true)
  	expect(response.location).to eq("http://path.to/example")
  end

  it "should render plain text" do
  	controller = TestHttpController.new(request)
	 	expect(controller.action_called).not_to be(true)
  	response = controller.perform(:render_action)
  	expect(response.body).to eq(["just plain text"])
  	expect(response['Content-Type']).to eq("text/plain")
  end

  it "should set the correct content type based on the format"

  it "should use a renderer"

  it "should camalize and dasherize the headers"

  it "removes the content for status codes 204, ..."
end