require 'volt/boot'

module Volt
  class CLI
    class Runner
      # Runs the ruby file at the path
      def self.run_file(path)
        Volt.boot(Dir.pwd)

        # Require in the file at path
        require './' + path
      end
    end
  end
end
