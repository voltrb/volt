require 'spec_helper'

unless RUBY_PLATFORM == 'opal'
  describe Volt::MiddlewareStack do
    before do
      @stack = Volt::MiddlewareStack.new
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