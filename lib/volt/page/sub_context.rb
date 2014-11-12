module Volt
  # A sub context takes in a hash of local variables that should be available
  # in front of the current context.  It basically proxies the local variables
  # first, then failing those proxies the context.
  #
  # SubContext is also used for the attrs in controllers.  You can pass return_nils
  # to have missing values return nil (as in attrs).
  class SubContext
    attr_reader :locals

    def initialize(locals=nil, context = nil, return_nils = false)
      @locals  = locals.stringify_keys if locals
      @context = context
      @return_nils = return_nils
    end

    def respond_to?(method_name)
      !!((@locals && @locals[method_name.to_s]) || (@context && @context.respond_to?(method_name)))
    end

    def inspect
      "#<SubContext #{@locals.inspect} context:#{@context.inspect}>"
    end

    def method_missing(method_name, *args, &block)
      method_name = method_name.to_s
      if @locals && @locals.key?(method_name)
        obj = @locals[method_name]

        # TODORW: Might get a normal proc, flag internal procs
        if obj.is_a?(Proc)
          obj = obj.call(*args)
        end
        return obj
      elsif @return_nils && method_name[-1] != '='
        return nil
      elsif @context
        return @context.send(method_name, *args, &block)
      end

      fail NoMethodError.new("undefined method `#{method_name}' for \"#{inspect}\":#{self.class}")
    end
  end
end
