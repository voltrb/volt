class BaseBinding
  attr_accessor :target, :context, :binding_name

  def initialize(target, context, binding_name)
    @target = target
    @context = context
    @binding_name = binding_name

    @@binding_number ||= 10000
  end

  def section
    @section ||= target.section(@binding_name)
  end
  
  def remove
    section.remove
  end
  
  def remove_anchors
    section.remove_anchors
  end
  
  def queue_update
    if Volt.server?
      # Run right away
      update
    else
      
    end
  end
  
  def value_from_getter(getter)
    # Evaluate the getter proc in the context
    return @context.instance_eval(&getter)
  end
end