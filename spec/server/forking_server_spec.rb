require 'spec_helper'
unless RUBY_PLATFORM == 'opal'
  require 'volt/server'

  describe Volt::ForkingServer do
    it 'should set polling an an option when using POLL_FS env' do
      ENV['POLL_FS'] = 'true'
      forking_server = Volt::ForkingServer.allocate

      # Lots of stubs, since we're working with the FS
      listener = double('listener')
      expect(listener).to receive(:start)
      expect(listener).to receive(:stop)
      expect(Listen).to receive(:to).with('/app/', {force_polling: true}).and_return(listener)
      expect(forking_server).to receive(:sync_mod_time)

      server = double('server')
      expect(server).to receive(:app_path).and_return('/app')
      forking_server.instance_variable_set(:@server, server)

      forking_server.start_change_listener
      ENV.delete('POLL_FS')

      forking_server.stop_change_listener
    end
  end
end