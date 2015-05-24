# The message encoder handles reading/writing the message to/from the socket.
# This includes encrypting and formatting.
module Volt
  module MessageBus
    class MessageEncoder
      attr_reader :encrypted
      def initialize
        # Message bus is encrypted by default
        @encrypted = (Volt.config.message_bus.try(:disable_encryption) != true)

        if @encrypted
          # Setup a RbNaCl simple box for handling encryption
          require 'base64'
          begin
            require 'rbnacl/libsodium'
          rescue LoadError => e
          # Ignore, incase they have libsodium installed locally
          end

          begin
            require 'rbnacl'
          rescue LoadError => e
            Volt.logger.error('Volt requires the rbnacl gem to enable encryption on the message bus.  Add it to the gemfile (and rbnacl-sodium if you don\'t have libsodium installed locally')
            raise e
          end

          # use the first 32 chars of the app secret for the encryption key.
          key = Base64.decode64(Volt.config.app_secret)[0..31]

          @encrypt_box = RbNaCl::SimpleBox.from_secret_key(key)
        end
      end

      def encrypt(message)
        if @encrypted
          @encrypt_box.encrypt(message)
        else
          message
        end
      end

      def decrypt(message)
        if @encrypted
          @encrypt_box.decrypt(message)
        else
          message
        end
      end

      def send_message(io, message)
        Marshal.dump(encrypt(message), io)
      end

      def receive_message(io)
        begin
          decrypt(Marshal.load(io))
        rescue EOFError => e
          # We get EOFError when the connection closes, return nil
          nil
        end
      end
    end
  end
end