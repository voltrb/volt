require 'volt/page/targets/base_section'
require 'volt/page/targets/attribute_section'
require 'volt/page/targets/binding_document/component_node'
require 'volt/page/targets/binding_document/html_node'

# AttributeTarget's provide an interface that can render bindings into
# a string that can then be used to update a attribute binding.

class AttributeTarget < ComponentNode  
  # TODO: improve
  def skip_current_queue_flush
    true
  end
  
  def section(*args)
    return AttributeSection.new(self, *args)
  end
end