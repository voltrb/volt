require 'spec_helper'

unless RUBY_PLATFORM == 'opal'
  describe Volt::SocketWithTimeout do
    it 'should setup a connection manually and then specify a timeout' do
      allow_any_instance_of(Socket).to receive(:connect)

      Volt::SocketWithTimeout.new('google.com', 80, 10)
    end
  end
end