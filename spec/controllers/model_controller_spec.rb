require 'spec_helper'

if RUBY_PLATFORM != 'opal'
  describe Volt::ModelController do
    it 'should accept a promise as a model and resolve it' do
      controller = Volt::ModelController.new(volt_app)

      promise = Promise.new

      controller.model = promise

      expect(controller.model).to eq(nil)

      promise.resolve(20)

      expect(controller.model).to eq(20)
    end

    it 'should not return true from loaded until the promise is resolved' do
      controller = Volt::ModelController.new(volt_app)

      promise = Promise.new
      controller.model = promise

      expect(controller.loaded?).to eq(false)

      promise.resolve(Volt::Model.new)
      expect(controller.loaded?).to eq(true)
    end

    it 'should provide a u method that disables reactive updates' do
      expect(Volt::Computation).to receive(:run_without_tracking)

      controller = Volt::ModelController.new(volt_app)
      controller.u { 5 }
    end
  end
end
