class Logger
  def initialize(log_to)
  end

  [:fatal, :info, :warn, :debug, :error].each do |method_name|
    define_method(method_name) do |text, &block|
      text = block.call if block

      `console[method_name](text);`
    end
  end
end
