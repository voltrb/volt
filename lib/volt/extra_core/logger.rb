if RUBY_PLATFORM == 'opal'
  # The basic front-end logger, log to console
  class Logger
    def initialize(*args)
      # TODO: handle options
    end

    [:fatal, :info, :warn, :debug, :error].each do |method_name|
      define_method(method_name) do |text, &block|
        text = block.call if block

        `console[method_name](text);`
      end
    end
  end

  class VoltLogger < Logger
  end
else
  require 'logger'

  module Volt
    class VoltLogger < Logger
      def initialize(current={})
        super(STDOUT)
        @current = current
        @formatter = Volt::VoltLoggerFormatter.new
      end

      def log_dispatch(class_name, method_name, run_time, args)
        @current = {
          args: args,
          class_name: class_name,
          method_name: method_name,
          run_time: run_time
        }

        log(Logger::INFO, task_dispatch_message)
      end

      def args
        @current[:args]
      end

      def class_name
        colorize(@current[:class_name].to_s, :light_blue)
      end

      def method_name
        colorize(@current[:method_name].to_s, :green)
      end

      def run_time
        colorize(@current[:run_time].to_s + 'ms', :green)
      end


      private

      def colorize(string, color)
        if STDOUT.tty? && string
          case color
          when :cyan
            "\e[1;34m" + string + "\e[0;37m"
          when :green
            "\e[0;32m" + string + "\e[0;37m"
          when :light_blue
            "\e[1;34m" + string + "\e[0;37m"
          when :purple
            "\e[1;35m" + string + "\e[0;37m"
          when :red
            "\e[1;31m" + string + "\e[0;37m"
          end
        else
          string.to_s
        end
      end

      def task_dispatch_message
        msg = "task #{class_name}##{method_name} in #{run_time}\n"
        if args.size > 0
          arg_str = args.map {|v| v.inspect }.join(', ')
          msg += "with args: #{arg_str}\n"
        end
        msg
      end
    end

    class VoltLoggerFormatter < Logger::Formatter
      def call(severity, time, progname, msg)
        "\n\n[#{severity}] #{msg2str(msg)}\n"
      end
    end
  end
end
