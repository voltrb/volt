require 'spec_helper'

if RUBY_PLATFORM != 'opal'
  require 'volt/server/socket_connection_handler'
  describe Volt::SocketConnectionHandler do
    let(:fake_dispatcher) { double("Dispatcher", volt_app: Volt.current_app)}

    let(:fake_session) {double("Faye::WebSocket")}

    before do
      @old_dispatcher = Volt::SocketConnectionHandler.dispatcher
      Volt::SocketConnectionHandler.dispatcher = fake_dispatcher
    end

    after do
      Volt::SocketConnectionHandler.dispatcher = @old_dispatcher
    end

    let(:connection_handler) { Volt::SocketConnectionHandler.new(fake_session) }

    subject!{ connection_handler }

    describe '#creation' do

      context 'with valid session' do

        it 'should append itself to @@channels' do
          expect(Volt::SocketConnectionHandler.channels).to include(subject)
        end

        it 'should trigger a client_connect event' do
          val = 0

          Volt.current_app.on("client_connect") do
            val = 1
          end

          # TODO: change the way this is handled, we shouldn't have to instantiate a new SocketConnectionHandler just for this test
          expect{Volt::SocketConnectionHandler.new(fake_session)}.to change{val}.by(1)
        end
      end
    end

    describe '#update' do
      context 'with nil user_id' do
        it 'should trigger a user_connect event when given a valid user_id' do
          id = 0
          Volt.current_app.on("user_connect") do |user_id|
            id = user_id
          end

          expect{subject.update_user_id(123)}.to change{id}.by(123)
        end
      end

      context 'with valid user_id' do
        it 'should trigger a user_disconnect event when given a nil user_id' do
          id = 0
          Volt.current_app.on("user_disconnect") do |user_id|
            id = user_id
          end

          subject.user_id = 123

          expect{subject.update_user_id(nil)}.to change{id}.by(123)
        end
      end
    end

    describe '#close' do
      it 'should trigger a client_disconnect event' do
        allow(Volt::SocketConnectionHandler.dispatcher).to receive(:close_channel).and_return true

        val = 0

        Volt.current_app.on("client_disconnect") do
          val = 1
        end

        expect{subject.closed}.to change{val}.by(1)
      end
      context 'with valid user_id' do
        it 'should trigger a user_disconnect event' do
          allow(Volt::SocketConnectionHandler.dispatcher).to receive(:close_channel).and_return true

          subject.user_id = 123

          id = 0

          Volt.current_app.on("user_disconnect") do |user_id|
            id = user_id
          end

          expect{subject.closed}.to change{id}.by(123)
        end
      end
    end
  end
end
