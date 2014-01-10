# AttributeSection provides a place to render templates that
# will be placed as text into an attribute.

require 'volt/templates/targets/base_section'

class AttributeSection
  def initialize(target, binding_name)
    @target = target
    @binding_name = binding_name
    # puts "init attr section on #{binding_name}"
  end
  
  def text=(text)
    set_content_and_rezero_bindings(text, {})
  end
  
	# Takes in our html and bindings, and rezero's the comment names, and the
	# bindings.  Returns an updated bindings hash
	def set_content_and_rezero_bindings(html, bindings)
    if @binding_name == 'main'
      @target.html = html
    else
      @target.find_by_binding_id(@binding_name).html = html
    end
    
    return bindings
  end
  
  def remove
    node = @target.find_by_binding_id(@binding_name)
    node.remove
  end
end