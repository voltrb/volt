require 'volt/page/targets/base_section'
require 'volt/page/targets/helpers/comment_searchers'

module Volt
  class DomSection < BaseSection
    include CommentSearchers

    def initialize(binding_name)
      @start_node = find_by_comment("$#{binding_name}")
      @end_node   = find_by_comment("$/#{binding_name}")
    end

    def text=(value)
      `
        this.$range().deleteContents();
        this.$range().insertNode(document.createTextNode(#{value}));
      `
    end

    def html=(value)
      new_nodes = build_from_html(value)

      self.nodes = `new_nodes.childNodes`
    end

    def remove
      range = self.range

      `
        range.deleteContents();
      `
    end

    def remove_anchors
      `
        this.start_node.parentNode.removeChild(this.start_node);
        this.end_node.parentNode.removeChild(this.end_node);
      `
      @start_node = nil
      @end_node   = nil
    end

    def insert_anchor_before_end(binding_name)
      Element.find(@end_node).before("<!-- $#{binding_name} --><!-- $/#{binding_name} -->")
    end

    def insert_anchor_before(binding_name, insert_after_binding)
      node = find_by_comment("$#{insert_after_binding}")
      Element.find(node).before("<!-- $#{binding_name} --><!-- $/#{binding_name} -->")
    end

    # Takes in an array of dom nodes and replaces the current content
    # with the new nodes
    def nodes=(nodes)
      range = self.range

      `
        range.deleteContents();

        for (var i=nodes.length-1; i >= 0; i--) {
          var node = nodes[i];

          node.parentNode.removeChild(node);
          range.insertNode(node);
        }
      `
    end

    # Returns the nearest DOM node that contains all of the section.
    def container_node
      range = self.range
      `range.commonAncestorContainer`
    end

    def set_template(dom_template)
      dom_nodes, bindings = dom_template.make_new

      children = nil
      `
      children = dom_nodes.childNodes;
        `

      # Update the nodes
      self.nodes = children

      `
      dom_nodes = null;
        `

      bindings
    end

    def range
      return @range if @range

      range = nil
      `
        range = document.createRange();
        range.setStartAfter(this.start_node);
        range.setEndBefore(this.end_node);
      `

      @range = range

      range
    end

    def inspect
      "<#{self.class}>"
    end
  end
end
