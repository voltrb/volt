module Volt
  class ViewHandler
    attr_reader :templates, :scope, :links

    def html
      last.html
    end

    def last
      @scope.last
    end

    # @param [String] - the path to the template file being processed
    # @param - the sprockets context, used for asset_url bindings
    # @param [Boolean] - if the processing should  default to body section
    def initialize(initial_path, sprockets_context=nil, allow_sections = true)
      @original_path = initial_path
      @sprockets_context = sprockets_context
      @links = []

      # Default to the body section
      initial_path += '/body' if allow_sections

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

    # Called from the view scope when an asset_url binding is hit.
    def link_asset(url, link=true)
      if @sprockets_context
        # Getting the asset_path also links to the context.
        linked_url = @sprockets_context.asset_path(url)
      else
        # When compiling on the server, we don't use sprockets (atm), so the
        # context won't exist.  Typically compiling on the server is just used
        # to test, so we simply return the url.
        linked_url = url
      end

      last << url if link

      linked_url
    end
  end
end
