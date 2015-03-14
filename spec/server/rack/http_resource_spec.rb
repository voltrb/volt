require 'volt/server/rack/http_resource'
require 'volt/server/rack/http_request'
require 'volt/controllers/http_controller'
require 'rack'

describe Volt::HttpResource do

  class SimpleController < Volt::HttpController
    attr_reader :action_called

    def index
      @action_called = true
      render "just some text"
    end
  end

  let(:app) { lambda {|env| [404, env, "app"] } }
  let(:http_resource) { Volt::HttpResource.new(app) }
  let(:env) { Rack::MockRequest.env_for("http://example.com/http_controller_test/simple_controller") }
  let(:request) { Volt::HttpRequest.new(env) }

  let! :test_controller do
    SimpleController.new(request)
  end

  before(:each) do
    allow(SimpleController).to receive(:new).and_return(test_controller)
  end

  it "should initialize the correct controller" do
    expect(SimpleController).to receive(:new).and_return(test_controller)
    response = http_resource.call(env)
    expect(response.body).to eq(["just some text"])
    expect(response.status).to eq(200)
    expect(test_controller.action_called).to eq(true)
  end
end
