require 'spec_helper'

if RUBY_PLATFORM != 'opal'
  class TestTask < Volt::Task
    def allowed_method(arg1, arg2)
      'yes' + arg1 + arg2
    end

    def set_cookie
      cookies._something = 'awesome'
    end
  end

  class WorkerPoolStub
    def post(*args)
      yield(*args)
    end
  end

  describe Volt::Dispatcher do
    let(:dispatcher) { Volt::Dispatcher.new(Volt.current_app) }

    before do
      Volt.logger = spy('Volt::VoltLogger')
      allow(Concurrent::ThreadPoolExecutor).to receive(:new).and_return(WorkerPoolStub.new)
    end

    after do
      # Cleanup, make volt make a new logger.  Otherwise this will leak out.
      Volt.logger = nil
    end

    it 'should only allow method calls on Task or above in the inheritance chain' do
      channel = double('channel')

      # Tasks handle their own conversion to EJSON
      msg = Volt::EJSON.stringify(['response', 0, 'yes it works', nil, nil])
      expect(channel).to receive(:send_string_message).with(msg)

      dispatcher.dispatch(channel, [0, 'TestTask', :allowed_method, {}, ' it', ' works'])
    end

    it 'should not allow eval' do
      channel = double('channel')

      expect(channel).to receive(:send_message).with('response', 0, nil, 'RuntimeError: unsafe method: eval', nil)

      dispatcher.dispatch(channel, [0, 'TestTask', :eval, '5 + 10'])
    end

    it 'should not allow instance_eval' do
      channel = double('channel')


      first = true
      expect(channel).to receive(:send_message).with("response", 0, nil, 'RuntimeError: unsafe method: instance_eval', nil)


      # .with('response', 0, nil, /RuntimeError: unsafe method: instance_eval/, nil)

      dispatcher.dispatch(channel, [0, 'TestTask', :instance_eval, '5 + 10'])
    end

    it 'should not allow #methods' do
      channel = double('channel')

      expect(channel).to receive(:send_message).with('response', 0, nil, 'RuntimeError: unsafe method: methods', nil)

      dispatcher.dispatch(channel, [0, 'TestTask', :methods])
    end

    it 'should log an info message before and after the dispatch' do
      channel = double('channel')

      allow(channel).to receive(:send_message).with('response', 0, 'yes it works', nil)
      expect(Volt.logger).to receive(:log_dispatch)

      dispatcher.dispatch(channel, [0, 'TestTask', :allowed_method, {}, ' it', ' works'])
    end

    it 'should let you set a cookie' do
      channel = double('channel')

      allow(channel).to receive(:send_message).with('response', 0, 'yes it works', {something:"awesome"})
      expect(Volt.logger).to receive(:log_dispatch)

      dispatcher.dispatch(channel, [0, 'TestTask', :set_cookie, {}])
    end

    it 'closes the channel' do
      disp = dispatcher
      channel    = Volt::ChannelStub.new
      # This doesn't do much except find typos, which is the only reason
      # I haven't deleted it. Work in progress -@RickCarlino
      this_spec_needs_improvement = disp.close_channel(channel)
    end
  end
end
