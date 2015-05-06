require 'spec_helper'

if RUBY_PLATFORM != 'opal'
  describe Volt::ModelController do
    it 'should accept a promise as a model and resolve it' do
      controller = Volt::ModelController.new

      promise = Promise.new

      controller.model = promise

      expect(controller.model).to eq(nil)

      promise.resolve(20)

      expect(controller.model).to eq(20)
    end

    it 'should not return true from loaded until the promise is resolved' do
      controller = Volt::ModelController.new

      promise = Promise.new
      controller.model = promise

      expect(controller.loaded?).to eq(false)

      promise.resolve(Volt::Model.new)
      expect(controller.loaded?).to eq(true)
    end
  end
end
