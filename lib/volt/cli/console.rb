require 'pry'

class Pry
  class REPL
    # To make the console more useful, we make it so we flush the event registry
    # after each line.  This makes it so events are triggered after each line.
    # To accomplish this we monkey-patch pry.
    def repl
      loop do
        case val = read
        when :control_c
          output.puts ""
          pry.reset_eval_string
        when :no_more_input
          output.puts "" if output.tty?
          break
        else
          output.puts "" if val.nil? && output.tty?
          return pry.exit_value unless pry.eval(val)
        end

        # Flush after each line
        Volt::Computation.flush!
        Volt::Timers.flush_next_tick_timers!
      end
    end
  end
end

module Volt
  class Console
    module Helpers
      def store
        $page.store
      end

      def page
        $page.page
      end
    end


    def self.start
      require 'pry'

      $LOAD_PATH << 'lib'
      ENV['SERVER'] = 'true'

      require 'volt'
      require 'volt/boot'
      require 'volt/volt/core'
      require 'volt/server/socket_connection_handler_stub'

      SocketConnectionHandlerStub.dispatcher = Dispatcher.new

      Volt.boot(Dir.pwd)

      Pry.config.prompt_name = 'volt'

      Pry.main.send(:include, Volt::Console::Helpers)

      # $page.pry
      Pry.start
    end
  end
end
