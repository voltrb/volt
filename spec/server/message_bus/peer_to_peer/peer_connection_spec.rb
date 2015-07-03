require 'spec_helper'

unless RUBY_PLATFORM == 'opal'
  describe Volt::MessageBus::PeerConnection do
    describe 'pass the server_id back and forth' do
      before do
        @socket = double('socket')

        @bus = double('message bus')
        expect(@bus).to receive(:server_id).and_return('server one')
        expect(@bus).to receive(:remove_duplicate_connections)

        thread = double('thread')
        allow(thread).to receive(:kill)
        allow(Thread).to receive(:new).and_return(thread)

        encoder = double('encoder')
        expect(Volt::MessageBus::MessageEncoder).to receive(:new).and_return(encoder)

        expect(encoder).to receive(:receive_message).with(@socket)
          .and_return('server two')

        expect(encoder).to receive(:send_message).with(@socket, 'server one')
      end

      it 'should on server' do
        Volt::MessageBus::PeerConnection.new(@socket, nil, nil, @bus, true).announce
      end

      it 'should pass the server_id back and forth to client' do
        Volt::MessageBus::PeerConnection.new(@socket, nil, nil, @bus).announce
      end
    end

    class MessageBusDouble
      def initialize(id, receiver)
        @id = id
        @receiver = receiver
      end

      def server_id
        @id
      end

      def remove_duplicate_connections
      end

      def remove_peer_connection(conn)
      end

      def handle_message(message)
        @receiver << message
      end

      def still_alive?(*args)
        false
      end
    end

    # Disable for jruby for now
    if RUBY_PLATFORM != 'java'
      it 'should pass messages between two peer conections' do
        responses1 = []
        bus1 = MessageBusDouble.new('server one', responses1)

        responses2 = []
        bus2 = MessageBusDouble.new('server two', responses2)

        server = TCPServer.new(0)
        port = server.addr[1]

        threads = []
        threads << Thread.new do
          @server = server.accept
        end

        threads << Thread.new do
          @client = TCPSocket.new('localhost', port)
        end

        threads.each(&:join)

        threads = []

        conn1 = nil
        threads << Thread.new do
          conn1 = Volt::MessageBus::PeerConnection.new(@server, nil, nil, bus1, true)
        end

        conn2 = nil
        threads << Thread.new do
          conn2 = Volt::MessageBus::PeerConnection.new(@client, nil, nil, bus2, false, bus2.server_id)
        end

        threads.each(&:join)

        conn1.publish('test message')

        loop do
          break if responses2.size > 0
          sleep 0.05
        end

        expect(responses2).to eq(['test message'])

        conn1.disconnect!
        conn2.disconnect!

      end
    end
  end
end