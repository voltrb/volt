module Volt
  class ViewHandler
    attr_reader :templates, :scope

    def html
      last.html
    end

    def last
      @scope.last
    end

    def initialize(initial_path, allow_sections = true)
      @original_path = initial_path

      # Default to the body section
      initial_path   += '/body' if allow_sections

      @scope     = [ViewScope.new(self, initial_path)]
      @templates = {}
    end

    def comment(comment)
      last << "<!--#{comment}-->"
    end

    def text(text)
      last << text
    end

    def binding(binding)
      @scope.last.add_binding(binding)
    end

    def start_tag(tag_name, attributes, unary)
      case tag_name[0]
        when ':'
          # Component
          last.add_component(tag_name, attributes, unary)
        else
          if tag_name == 'textarea'
            @in_textarea = true
            last.add_textarea(tag_name, attributes, unary)
          else

            # Normal tag
            attributes = last.process_attributes(tag_name, attributes)
            attr_str   = last.attribute_string(attributes)

            last << "<#{tag_name}#{attr_str}#{unary ? ' /' : ''}>"
          end
      end
    end

    def end_tag(tag_name)
      if @in_textarea && tag_name == 'textarea'
        last.close_scope
        @in_textarea = nil
      elsif tag_name[0] == ':'
        # Closing a volt tag
        last.close_scope
      else
        last << "</#{tag_name}>"
      end
    end

    def start_section(tag_name, attributes, unary)
      path = last.path
      # Start of section
      if @in_section
        # Close any previous sections
        last.close_scope
      else
        # This is the first time we've hit a section header, everything
        # outside of the headers should be removed
        @templates = {}
      end

      @in_section = tag_name[1..-1]

      # Set the new path to include the section
      new_path    = @original_path + '/' + @in_section
      @scope      = [ViewScope.new(self, new_path)]
    end
  end
end
