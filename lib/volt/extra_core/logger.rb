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
else
  require 'logger'

  module Volt
    class VoltLogger < Logger
      def initialize(opts={})
        super(STDOUT)
        @opts = opts
        @formatter = Volt::VoltLoggerFormatter.new
      end

      def log_dispatch
        log(Logger::INFO, task_dispatch_message)
      end

      def args
        if @opts[:args]
          @args ||= @opts[:args].join(", ")
        else
          @args ||= ''
        end
      end

      def class_name
        if @opts[:class_name]
          @class_name ||= colorize(@opts[:class_name], :light_blue)
        else
          @class_name ||= ''
        end
      end

      def method_name
        if @opts[:method_name]
          @method_name ||= colorize(@opts[:method_name], :green)
        else
          @method_name ||= ''
        end
      end

      def run_time
        if @opts[:run_time]
          @run_time ||= colorize(@opts[:run_time].to_s + 'ms', :green)
        else
          @run_time ||= ''
        end
      end


      private

      def colorize(string, color)
        if STDOUT.tty?
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
          string
        end
      end

      def task_dispatch_message
        "TASK #{class_name}##{method_name}\n" +
        "WITH ARGS #{args}\n" +
        "FINISHED in #{run_time}"
      end
    end

    class VoltLoggerFormatter < Logger::Formatter
      def call(severity, time, progname, msg)
        "\n\n#{severity}: #{msg2str(msg)}\n"
      end
    end
  end
end

