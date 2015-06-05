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
      def initialize(current = {})
        super(STDOUT)
        @current = current
        @formatter = Volt::VoltLoggerFormatter.new
      end

      def log_dispatch(class_name, method_name, run_time, args, error)
        @current = {
          args: args,
          class_name: class_name,
          method_name: method_name,
          run_time: run_time
        }

        level = error ? Logger::ERROR : Logger::INFO
        text = TaskLogger.task_dispatch_message(self, args)

        if error
          text += "\n" + colorize(error.to_s, :red)
          if error.is_a?(Exception) && !error.is_a?(VoltUserError)
            backtrace = error.try(:backtrace)
            if backtrace
              text += "\n" + colorize(error.backtrace.join("\n"), :red)
            end
          end
        end

        log(level, text)
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

      def log_with_color(msg, color)
        Volt.logger.info(colorize(msg, color))
      end

      def error(msg)
        msg ||= yield
        super(colorize(msg, :red))
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
    end

    class VoltLoggerFormatter < Logger::Formatter
      def call(severity, time, progname, msg)
        "\n\n[#{severity}] #{msg2str(msg)}\n"
      end
    end
  end
end
