require 'spec_helper'

unless RUBY_PLATFORM == 'opal'
  describe Volt::MessageBus::PeerServer do
    describe "ip and ports" do
      before do
        allow_any_instance_of(Volt::MessageBus::PeerServer).to receive(:run_server)
      end

      it 'should use Volt.config.message_bus.bind_port_ranges to connect' do
        config = double('volt/config')
        expect(Volt.config).to receive(:message_bus).and_return(config)
          .at_least(:once)

        ports = [5000,6000,7000]

        expect(config).to receive(:bind_port_ranges).and_return(ports)
          .at_least(:once)

        tried_ports = []

        # Act like all sockets are in use to test NoAvailablePortException
        expect(TCPServer).to receive(:new) do |port|
          tried_ports << port
        end.at_least(:once).and_raise(Errno::EADDRINUSE)

        expect do
          peer_server = Volt::MessageBus::PeerServer.new(nil)
        end.to raise_error(Volt::MessageBus::NoAvailablePortException)

        expect(tried_ports.sort).to eq(ports)
      end
    end

    it 'should start a server that creates peer connections when accepted' do
      expect(Thread).to receive(:new).and_yield
      # The PeerConnection that will be created
      new_peer = double('new peer connection')

      message_bus = double('message bus')
      expect(message_bus).to receive(:add_peer_connection) do |peer_conn|
        expect(peer_conn).to eq(new_peer)
        # Raise an exception to get out of the loop
      end.and_raise(Exception)

      # Stub the socket connection
      socket = double('tcp server socket')

      # Stub the incoming connection
      connection = double('client socket connection')

      expect(socket).to receive(:accept).and_return(connection)

      expect(Thread).to receive(:start).with(connection).and_yield(connection)
      expect(TCPServer).to receive(:new).and_return(socket)

      expect(Volt::MessageBus::PeerConnection).to receive(:new)
        .and_return(new_peer)

      expect do
        peer_server = Volt::MessageBus::PeerServer.new(message_bus)
      end.to raise_error(Exception)
    end

  end
end