require 'volt/boot'

module Volt
  class CLI
    class Runner
      # Runs the ruby file at the path
      def self.run_file(path)
        app = Volt.boot(Dir.pwd)

        # Require in the file at path
        require './' + path

        # disconnect from the message bus and flush all messages
        app.message_bus.disconnect!
      end
    end
  end
end
