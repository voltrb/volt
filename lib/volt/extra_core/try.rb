class Object
  
  class TryProxy
    def initialize(original)
      @original = original
    end
    
    def method_missing(method_name, *args, &block)
      if @original.respond_to?(method_name)
        
      else
        NilProxy.new
      end
    end
  end
  
  class NilProxy
    def method_missing(method_name, *args, &block)
      if @original.respond_to?(method_name)
        
      else
        NilProxy.new
      end
    end
  end
  
  def try
    
  end
  
end