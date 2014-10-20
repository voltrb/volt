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
end