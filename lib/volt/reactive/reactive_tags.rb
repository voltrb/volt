require 'volt/reactive/destructive_methods'

# ReactiveTags provide an easy way to specify how a class deals with 
# reactive events and method calls.als
module ReactiveTags
  class MethodTags
    attr_accessor :destructive, :pass_reactive, :reacts_with
  end

  class MethodTagger
    attr_reader :method_tags
    
    def initialize
      @method_tags = MethodTags.new
    end
    
    def destructive!(&block)
      @method_tags.destructive = block || true
    end
    
    def pass_reactive!
      @method_tags.pass_reactive = true
    end
  end
  
  module ClassMethods  
    def tag_method(method_name, &block)
      tagger = MethodTagger.new
    
      tagger.instance_eval(&block)
    
      @reactive_method_tags ||= {}
      @reactive_method_tags[method_name.to_sym] = tagger.method_tags
      
      # Track a destructive method
      if tagger.method_tags.destructive
        DestructiveMethods.add_method(method_name)
      end
    end
    
    def tag_all_methods(&block)
      tagger = MethodTagger.new
      
      tagger.instance_eval(&block)
    
      @reactive_method_tags ||= {}
      @reactive_method_tags[:__all_methods] = tagger.method_tags
    end
  end

  # Returns a reference to the tags on a method
  def reactive_method_tag(method_name, tag_name, klass=self.class)
    # Check to make sure we haven't gone above a class that has included
    # ReactiveTags
    return nil if !klass || !klass.method_defined?(:reactive_method_tag)
    
    tags = klass.instance_variable_get('@reactive_method_tags')

    if tags && (tag = tags[method_name.to_sym]) && (tag = tag.send(tag_name))
      return tag
    end
    
    return self.reactive_method_tag(method_name, tag_name, klass.superclass)
  end
  

  def self.included(base)
    base.send(:extend, ClassMethods)
    base.send(:include, Events)
  end
end