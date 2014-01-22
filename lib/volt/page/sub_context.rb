# A sub context takes in a hash of local variables that should be available
# in front of the current context.  It basically proxies the local variables 
# first, then failing those proxies the context.

class SubContext
  attr_reader :locals
  
  def initialize(locals, context=nil)
    @locals = locals.stringify_keys
    @context = context
  end
  
  def respond_to?(method_name)
    !!(@locals[method_name.to_s] || (@context && @context.respond_to?(method_name)) || super)
  end
  
  def method_missing(method_name, *args, &block)
    method_name = method_name.to_s
    if @locals[method_name]
      return @locals[method_name]
    elsif @context
      return @context.send(method_name, *args, &block)
    end

    raise NoMethodError.new("undefined method `#{method_name}' for \"#{self.inspect}\":#{self.class.to_s}")
  end
end