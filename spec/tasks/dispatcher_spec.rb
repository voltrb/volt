if RUBY_PLATFORM != 'opal'
  class TestTask < Volt::TaskHandler
    def allowed_method(arg1)
      return 'yes' + arg1
    end
  end


  describe Volt::Dispatcher do

    it 'should only allow method calls on TaskHandler or above in the inheritance chain' do
      channel = double('channel')

      expect(channel).to receive(:send_message).with('response', 0, 'yes works', nil)

      Volt::Dispatcher.new.dispatch(channel, [0, 'TestTask', :allowed_method, {}, ' works'])
    end

    it 'should not allow eval' do
      channel = double('channel')

      expect(channel).to receive(:send_message).with('response', 0, nil, RuntimeError.new('unsafe method: eval'))

      Volt::Dispatcher.new.dispatch(channel, [0, 'TestTask', :eval, '5 + 10'])
    end

    it 'should not allow instance_eval' do
      channel = double('channel')

      expect(channel).to receive(:send_message).with('response', 0, nil, RuntimeError.new('unsafe method: instance_eval'))

      Volt::Dispatcher.new.dispatch(channel, [0, 'TestTask', :instance_eval, '5 + 10'])
    end

    it 'should not allow #methods' do
      channel = double('channel')

      expect(channel).to receive(:send_message).with('response', 0, nil, RuntimeError.new('unsafe method: methods'))

      Volt::Dispatcher.new.dispatch(channel, [0, 'TestTask', :methods])
    end
  end
end
