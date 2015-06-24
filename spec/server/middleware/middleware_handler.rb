require 'spec_helper'

unless RUBY_PLATFORM == 'opal'
  describe Volt::MiddlewareStack do
    before do
      @stack = Volt::MiddlewareStack.new
    end

    it 'should set_app' do
      app = double('rack app')
      @stack.set_app(app)
      expect(@stack.instance_variable_get('@app')).to eq(app)
    end

    it 'should insert a middleware at the end of the stack when calling use' do
      middleware1 = double('middleware1')
      @stack.use(middleware1, 'arg1')

      expect(@stack.middlewares).to eq([
        [[middleware1, 'arg1'], nil]
      ])
    end
  end
end
