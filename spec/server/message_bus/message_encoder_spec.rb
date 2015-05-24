require 'spec_helper'

unless RUBY_PLATFORM == 'opal'
  describe Volt::MessageBus do
    before do
      # Stub socket stuff
      allow_any_instance_of(Volt::MessageBus).to receive(:connect_to_peers).and_return(nil)
    end

    describe "encryption" do
      before do
        @msg_bus_config = double('volt/config')

        expect(Volt.config).to receive(:message_bus).and_return(@msg_bus_config)
      end

      it 'should get disabled state from Volt.config.message_bus.encryption_disabled' do
        expect(@msg_bus_config).to receive(:disable_encryption).and_return(true)

        encoder = Volt::MessageBus::MessageEncoder.new

        expect(encoder.encrypted).to eq(false)
      end

      it 'should get enabled state from Volt.config.message_bus.encryption_disabled' do
        expect(@msg_bus_config).to receive(:disable_encryption).and_return(false)

        encoder = Volt::MessageBus::MessageEncoder.new

        expect(encoder.encrypted).to eq(true)
      end
    end

    it 'should encrypt and decrypt' do
      message = 'this is my message that should be encrypted'
      encoder = Volt::MessageBus::MessageEncoder.new

      encrypted_message = encoder.encrypt(message)

      # Should be encrypted
      expect(encrypted_message).to_not eq(message)

      decrypted_message = encoder.decrypt(encrypted_message)

      expect(decrypted_message).to eq(message)
    end

  end
end