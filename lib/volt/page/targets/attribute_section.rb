# AttributeSection provides a place to render templates that
# will be placed as text into an attribute.

require 'volt/page/targets/base_section'

module Volt
  class AttributeSection < BaseSection
    def initialize(target, binding_name)
      @target       = target
      @binding_name = binding_name
    end

    def text=(text)
      set_content_and_rezero_bindings(text, {})
    end

    def html=(value)
      set_content_and_rezero_bindings(value, {})
    end

    def insert_anchor_before_end(binding_name)
      end_node = @target.find_by_binding_id(@binding_name)
      if end_node.is_a?(ComponentNode)
        component_node = ComponentNode.new(binding_name, end_node, end_node.root || end_node)
        end_node.insert(-1, component_node)
      else
        raise "can not insert on HtmlNode"
      end
    end

    # When using bindings, we have to change the binding id so we don't reuse
    # the same id when rendering a binding multiple times.
    def rezero_bindings(html, bindings)
      @@base_binding_id ||= 20_000
      # rezero
      parts  = html.split(/(\<\!\-\- \$\/?[0-9]+ \-\-\>)/).reject { |v| v == '' }

      new_html = []
      new_bindings = {}
      id_map = {}

      parts.each do |part|
        case part
          when /\<\!\-\- \$[0-9]+ \-\-\>/
            # Open
            binding_id = part.match(/\<\!\-\- \$([0-9]+) \-\-\>/)[1].to_i
            binding = bindings[binding_id]
            new_bindings[@@base_binding_id] = binding if binding

            new_html << "<!-- $#{@@base_binding_id} -->"
            id_map[binding_id] = @@base_binding_id
            @@base_binding_id += 1
          when /\<\!\-\- \$\/[0-9]+ \-\-\>/
            # Close
            binding_id = part.match(/\<\!\-\- \$\/([0-9]+) \-\-\>/)[1].to_i
            new_html << "<!-- $/#{id_map[binding_id]} -->"
          else
            # html string
            new_html << part
        end
      end

      return new_html.join(''), new_bindings
    end

    # Takes in our html and bindings, and rezero's the comment names, and the
    # bindings.  Returns an updated bindings hash
    def set_content_and_rezero_bindings(html, bindings)
      html, bindings = rezero_bindings(html, bindings)

      if @binding_name == 'main'
        @target.html = html
      else
        @target.find_by_binding_id(@binding_name).html = html
      end

      bindings
    end

    def remove
      # TODO: is this getting run for no reason?
      node = @target.find_by_binding_id(@binding_name)
      node.remove if node
    end
  end
end
