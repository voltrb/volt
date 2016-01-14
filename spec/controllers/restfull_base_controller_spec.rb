require 'spec_helper'

if RUBY_PLATFORM != 'opal'
  require 'volt/controllers/restfull_base_controller'
  require 'volt/server/rack/http_request'
  require 'volt/server/rack/http_resource'

  describe Volt::RestfullBaseController do
    class TestRestfulController < Volt::RestfullBaseController

      attr_accessor :the_model, :the_collection, :the_collection_name, :the_resource_params

      def model_test
        self.the_model = model
      end

      def collection_test
        self.the_collection = collection
        self.the_collection_name = collection_name
      end

      def params_test
        self.the_resource_params = resource_params
      end

    end

    class StaticRestfulController < Volt::RestfullBaseController
      attr_accessor :the_model

      model :issue

      def model_test
        self.the_model = model
      end
    end

    class ImplementedRestfulController < Volt::RestfullBaseController
      attr_accessor :the_resource

      def create
        self.the_resource = resource
      end

      def update
        self.the_resource = resource
      end

      def show
        self.the_resource = resource
      end

      def destroy
        self.the_resource = resource
      end
    end

    let(:app) { ->(env) { [404, env, 'app'] } }

    def request(url='http://example.com/issues')
      Volt::HttpRequest.new(
        Rack::MockRequest.env_for(url, 'CONTENT_TYPE' => 'application/json;charset=utf-8'))
    end


    let(:controller) { TestRestfulController.new(volt_app, {}, request) }

    before(:each) do
      store.issues.reverse.each do |issue|
        issue.destroy
      end
    end

    it 'should set the model from the params' do
      controller = TestRestfulController.new(
        volt_app, {model: 'issue'}, request 
      )
      controller.perform(:model_test)
      expect(controller.the_model).to eq(:issue)
    end

    it 'should use a static model if set' do
      controller = StaticRestfulController.new(
        volt_app, {model: 'none'}, request 
      )
      controller.perform(:model_test)
      expect(controller.the_model).to eq(:issue)
    end

    it 'should set the collection based on the model name' do
      controller = TestRestfulController.new(
        volt_app, {model: 'issue'}, request)

      controller.perform(:collection_test)
      expect(controller.the_collection_name).to eq(:issues)
      expect(controller.the_collection).to be_kind_of(Volt::ArrayModel)
      expect(controller.the_collection.new).to be_kind_of(Issue)
    end

    it 'should set the correct resource_params based on the model name' do
      issue = { name: 'test' }
      controller = TestRestfulController.new(
        volt_app, {model: 'issue', issue: issue }, request 
      )
      controller.perform(:params_test)
      expect(controller.the_resource_params).to eq(issue)
    end

    it 'should setup a new instance of a model with the given params for the create action' do
      issue = { name: 'test'  }
      controller = ImplementedRestfulController.new(
        volt_app, {model: 'issue', issue: issue }, request 
      )
      controller.perform(:create)
      expect(controller.the_resource).to be_kind_of(Issue)
      expect(controller.the_resource.root).to be_kind_of(Issue)
      new_issue = controller.the_resource.to_h
      new_issue.delete(:id)
      expect(new_issue).to eq(issue)
    end

    it 'should setup a buffer of a model for the update action' do
      issue = store.issues.create({ name: 'test' }).sync
      controller = ImplementedRestfulController.new(
        volt_app, { model: 'issue', id: issue.id }, request 
      )
      controller.perform(:update)
      expect(controller.the_resource.to_h).to eq(issue.to_h)
      expect(controller.the_resource.root).to eq(store)
      expect(controller.the_resource.buffer?).to be(true)
    end

    it 'should setup the model for the show action' do
      issue = store.issues.create({ name: 'test' }).sync
      controller = ImplementedRestfulController.new(
        volt_app, { model: 'issue', id: issue.id }, request 
      )
      controller.perform(:show)
      expect(controller.the_resource.to_h).to eq(issue.to_h)
      expect(controller.the_resource.root).to eq(store)
      expect(controller.the_resource.buffer?).to be(false)
    end

    it 'should setup the model for the delete action' do
      issue = store.issues.create({ name: 'test' }).sync
      controller = ImplementedRestfulController.new(
        volt_app, { model: 'issue', id: issue.id }, request 
      )
      controller.perform(:show)
      expect(controller.the_resource.to_h).to eq(issue.to_h)
      expect(controller.the_resource.root).to eq(store)
      expect(controller.the_resource.buffer?).to be(false)
    end

    it 'should respond with http 404 not found if the resource could not be found' do
      controller = ImplementedRestfulController.new(
        volt_app, { model: 'issue', id: 0 }, request 
      )
      response = controller.perform(:show)
      expect(response.status).to eq(404)
    end

    it 'should respond with http 500 internal server error no model is set' do
      controller = ImplementedRestfulController.new(
        volt_app, { }, request 
      )
      response = controller.perform(:show)
      expect(response.status).to eq(500)
    end
  end
end
