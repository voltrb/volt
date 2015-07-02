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
          output.puts ''
          pry.reset_eval_string
        when :no_more_input
          output.puts '' if output.tty?
          break
        else
          output.puts '' if val.nil? && output.tty?
          return pry.exit_value unless pry.eval(val)
        end

        # Flush after each line
        Volt::Computation.flush!
        Volt::Timers.flush_next_tick_timers!
      end
    end
  end

  # The following causes promises in the console to auto-resolve, making it
  # easier to see your data, but harder to follow along.  Currently off by
  # default.
  if ENV['AUTO_RESOLVE']
    def evaluate_ruby(code)
      inject_sticky_locals!
      exec_hook :before_eval, code, self

      result = current_binding.eval(code, Pry.eval_path, Pry.current_line)

      if result.is_a?(Promise)
        result = result.sync
      end

      set_last_result(result, code)
    ensure
      update_input_history(code)
      exec_hook :after_eval, result, self
    end
  end
end

module Volt
  class Console
    module Helpers
      def store
        @volt_app.store
      end

      def page
        @volt_app.page
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

      # Boot the volt app
      volt_app = Volt.boot(Dir.pwd)

      SocketConnectionHandlerStub.dispatcher = Dispatcher.new(volt_app)

      Pry.config.prompt_name = 'volt'

      Pry.main.instance_variable_set('@volt_app', volt_app)
      Pry.main.send(:include, Volt::Console::Helpers)

      Pry.start
    end
  end
end
