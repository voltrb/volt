# The BaseBinding class is the base for all bindings.  It takes
# 4 arguments that should be passed up from the children (via super)
#
# 1. page - this class instance should provide:
#            - a #templates methods that returns a hash for templates
#            - an #events methods that returns an instance of DocumentEvents
# 2. target -  an DomTarget or AttributeTarget
# 3. context - the context object the binding will be evaluated in
# 4. binding_name - the id for the comment (or id for attributes) where the
#                   binding will be inserted.
class BaseBinding
  attr_accessor :target, :context, :binding_name

  def initialize(page, target, context, binding_name)
    @page = page
    @target = target
    @context = context
    @binding_name = binding_name

    @@binding_number ||= 10000
  end

  def dom_section
    @dom_section ||= target.dom_section(@binding_name)
  end

  def remove
    @dom_section.remove if @dom_section

    # Clear any references
    @target = nil
    @context = nil
    @dom_section = nil
  end

  def remove_anchors
    @dom_section.remove_anchors if @dom_section
  end
end
