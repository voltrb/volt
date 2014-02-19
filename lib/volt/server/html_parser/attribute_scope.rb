# Included into ViewScope to provide processing for attributes
module AttributeScope
  # Take the attributes and create any bindings
  def process_attributes(tag_name, attributes)
    new_attributes = attributes.dup

    attributes.each_pair do |name, value|
      if name[0..1] == 'e-'
        process_event_binding(tag_name, new_attributes, name, value)
      else
        process_attribute(new_attributes, name, value)
      end
    end
    
    return new_attributes
  end
  
  def process_event_binding(tag_name, attributes, name, value)
    id = add_id_to_attributes(attributes)
    
    event = name[2..-1]
    
    if tag_name == 'a'
      # For links, we need to add blank href to make it clickable.
      attributes['href'] ||= ''
    end

    save_binding(id, "lambda { |__p, __t, __c, __id| EventBinding.new(__p, __t, __c, __id, #{event.inspect}, Proc.new {|event| #{value} })}")
  end
  
  def process_attribute(attributes, attribute_name, value)
    parts = value.split(/(\{[^\}]+\})/).reject(&:blank?)
    binding_count = parts.count {|p| p[0] == '{' && p[-1] == '}'}

    # if this attribute has bindings
    if binding_count > 0
      # Setup an id
      id = add_id_to_attributes(attributes)
    
      if parts.size > 1
        # Multiple bindings
        add_multiple_attribute(id, attribute_name, value)
      elsif parts.size == 1 && binding_count == 1
        # A single binding
        add_single_attribute(id, attribute_name, parts)
      end
      
      # Remove the attribute
      attributes.delete(attribute_name)
    end
  end
  
  # Add an attribute binding on the tag, bind directly to the getter in the binding
  def add_single_attribute(id, attribute_name, parts)
    getter = parts[0][1..-2]
    
    save_binding(id, "lambda { |__p, __t, __c, __id| AttributeBinding.new(__p, __t, __c, __id, #{attribute_name.inspect}, Proc.new { #{getter} }) }")
  end


  def add_multiple_attribute(id, attribute_name, content)
    case attribute_name
    when 'checked', 'value'
      if parts.size > 1
        # Multiple ReactiveValue's can not be passed to value or checked attributes.
        raise "Multiple bindings can not be passed to a #{attribute_name} binding."
      end
    end
    
    reactive_template_path = add_reactive_template(content)
    
    save_binding(id, "lambda { |__p, __t, __c, __id| AttributeBinding.new(__p, __t, __c, __id, #{attribute_name.inspect}, Proc.new { ReactiveTemplate.new(__p, __c, #{reactive_template_path.inspect}) }) }")
  end
  
  def add_reactive_template(content)
    path = @path + "/_rv#{@binding_number}"
    new_handler = ViewHandler.new(path, false)
    @binding_number += 1
    
    SandlebarsParser.new(content, new_handler)
    
    # Close out the last scope
    new_handler.scope.last.close_scope

    # Copy in the templates from the new handler
    new_handler.templates.each_pair do |key, value|
      @handler.templates[key] = value
    end
    
    return path
  end
  
  def add_id_to_attributes(attributes)
    id = attributes['id'] ||= "id#{@binding_number}"
    @binding_number += 1
    
    return id.to_s
  end
end