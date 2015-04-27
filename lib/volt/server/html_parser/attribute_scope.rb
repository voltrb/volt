module Volt
  # Included into ViewScope to provide processing for attributes
  module AttributeScope
    # Take the attributes and create any bindings
    def process_attributes(tag_name, attributes)
      new_attributes = attributes.dup

      attributes.each_pair do |name, value|
        if name[0..1] == 'e-'
          process_event_binding(tag_name, new_attributes, name, value)
        else
          process_attribute(tag_name, new_attributes, name, value)
        end
      end

      new_attributes
    end

    def process_event_binding(tag_name, attributes, name, value)
      id = add_id_to_attributes(attributes)

      event = name[2..-1]

      if tag_name == 'a'
        # For links, we need to add blank href to make it clickable.
        attributes['href'] ||= ''
      end

      # Remove the e- attribute
      attributes.delete(name)

      save_binding(id, "lambda { |__p, __t, __c, __id| Volt::EventBinding.new(__p, __t, __c, __id, #{event.inspect}, Proc.new {|event| #{value} })}")
    end

    # Takes a string and splits on bindings, returns the string split on bindings
    # and the number of bindings.
    def binding_parts_and_count(value)
      if value.is_a?(String)
        parts = value.split(/(\{\{[^\}]+\}\})/).reject(&:blank?)
      else
        parts = ['']
      end
      binding_count = parts.count { |p| p[0] == '{' && p[1] == '{' && p[-2] == '}' && p[-1] == '}' }

      [parts, binding_count]
    end

    def process_attribute(tag_name, attributes, attribute_name, value)
      parts, binding_count = binding_parts_and_count(value)

      # if this attribute has bindings
      if binding_count > 0
        # Setup an id
        id = add_id_to_attributes(attributes)

        if parts.size > 1
          # Multiple bindings
          add_multiple_attribute(tag_name, id, attribute_name, parts, value)
        elsif parts.size == 1 && binding_count == 1
          # A single binding
          add_single_attribute(id, attribute_name, parts)
        end

        # Remove the attribute
        attributes.delete(attribute_name)
      end
    end

    # TODO: We should use a real parser for this
    def getter_to_setter(getter)
      getter = getter.strip.gsub(/\(\s*\)/, '')

      # Check to see if this can be converted to a setter
      if getter[0] =~ /^[a-z_]/ && getter[-1] != ')'
        # Convert a getter into a setter
        if getter.index('.') || getter.index('@')
          prefix = ''
        else
          prefix = 'self.'
        end

        "#{prefix}#{getter}=(val)"
      else
        "raise \"could not auto generate setter for `#{getter}`\""
      end
    end

    # Add an attribute binding on the tag, bind directly to the getter in the binding
    def add_single_attribute(id, attribute_name, parts)
      getter = parts[0][2...-2].strip

      # if getter.index('@')
      #   raise "Bindings currently do not support instance variables"
      # end

      setter = getter_to_setter(getter)

      save_binding(id, "lambda { |__p, __t, __c, __id| Volt::AttributeBinding.new(__p, __t, __c, __id, #{attribute_name.inspect}, Proc.new { #{getter} }, Proc.new { |val| #{setter} }) }")
    end

    def add_multiple_attribute(tag_name, id, attribute_name, parts, content)
      case attribute_name
        when 'checked', 'value'
          if parts.size > 1
            if tag_name == 'textarea'
              fail "The content of text area's can not be bound to multiple bindings."
            else
              # Multiple values can not be passed to value or checked attributes.
              fail "Multiple bindings can not be passed to a #{attribute_name} binding: #{parts.inspect}"
            end
          end
      end

      string_template_renderer_path = add_string_template_renderer(content)

      save_binding(id, "lambda { |__p, __t, __c, __id| Volt::AttributeBinding.new(__p, __t, __c, __id, #{attribute_name.inspect}, Proc.new { Volt::StringTemplateRender.new(__p, __c, #{string_template_renderer_path.inspect}) }) }")
    end

    def add_string_template_renderer(content)
      path            = @path + "/_rv#{@binding_number}"
      new_handler     = ViewHandler.new(path, false)
      @binding_number += 1

      SandlebarsParser.new(content, new_handler)

      # Close out the last scope
      new_handler.scope.last.close_scope

      # Copy in the templates from the new handler
      new_handler.templates.each_pair do |key, value|
        @handler.templates[key] = value
      end

      path
    end

    def add_id_to_attributes(attributes)
      id              = attributes['id'] ||= "id#{@binding_number}"
      @binding_number += 1

      id.to_s
    end

    def attribute_string(attributes)
      attr_str = attributes.map { |v| "#{v[0]}=\"#{v[1]}\"" }.join(' ')
      if attr_str.size > 0
        # extra space
        attr_str = ' ' + attr_str
      end

      attr_str
    end
  end
end
