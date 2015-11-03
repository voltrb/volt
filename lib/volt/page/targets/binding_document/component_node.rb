require 'volt/page/targets/binding_document/html_node'
require 'volt/page/targets/binding_document/tag_node'
require 'volt/reactive/eventable'

module Volt
  # Component nodes contain an array of HtmlNodes, TagNodes and ComponentNodes.
  # Instead of providing a full DOM API, component nodes are the branch
  # nodes and html/tag nodes are the leafs.  This is all we need to produce
  # the html from templates outside of a normal dom.
  class ComponentNode < BaseNode
    include Eventable

    attr_accessor :parent, :binding_id, :nodes, :root

    def initialize(binding_id = nil, parent = nil, root = nil)
      @nodes      = []
      @binding_id = binding_id
      @parent     = parent
      @root       = root
    end

    def changed!
      if @root
        @root.changed!
      else
        trigger!('changed')
      end
    end

    def text=(text)
      self.html = text
    end

    def html=(html)
      tag_regex = /(\<[^\>]+\>)/
      parts  = html.split(tag_regex).reject { |v| v == '' }

      # Clear current nodes
      @nodes = []

      current_node = self

      parts.each do |part|
        case part
        when /\<\!\-\- \$[0-9]+ \-\-\>/
          # Open
          binding_id = part.match(/\<\!\-\- \$([0-9]+) \-\-\>/)[1].to_i

          sub_node = ComponentNode.new(binding_id, current_node, @root || self)
          current_node << sub_node
          current_node = sub_node
        when /\<\!\-\- \$\/[0-9]+ \-\-\>/
          # Close
          # binding_id = part.match(/\<\!\-\- \$\/([0-9]+) \-\-\>/)[1].to_i

          current_node = current_node.parent
        when /^<\/[-!\:A-Za-z0-9_]+[^>]*>/
          # end tag, just store it as html for performance
          current_node << HtmlNode.new(part)
        when /\<[^\>]+\>/
          # start tag or unary
          current_node << TagNode.new(part)
        else
          # html string
          current_node << HtmlNode.new(part)
        end
      end

      changed!
    end

    def <<(node)
      @nodes << node
    end

    def insert(index, node)
      @nodes.insert(index, node)
      changed!
    end

    def to_html
      str = []
      @nodes.each do |node|
        str << node.to_html
      end

      str.join('')
    end

    def find_by_binding_id(binding_id)
      return self if @binding_id == binding_id

      @nodes.each do |node|
        if node.is_a?(ComponentNode)
          val = node.find_by_binding_id(binding_id)
          return val if val
        end
      end

      nil
    end

    # TODO: This is an inefficient implementation since it has to walk the tree,
    # we should make it so it caches nodes after the first walk (similar to
    # how browsers handle getElementById)
    def find_by_tag_id(tag_id)
      @nodes.each do |node|
        if node.is_a?(ComponentNode)
          # Walk down nodes
          val = node.find_by_tag_id(tag_id)
          return val if val
        elsif node.is_a?(TagNode)
          # Found a matching tag
          return node if node.tag_id == tag_id
        end
      end

      nil
    end

    def remove
      @nodes = []

      changed!
    end

    def remove_anchors
      fail 'not implemented'

      @parent.nodes.delete(self)

      changed!
      @parent     = nil
      @binding_id = nil
    end

    def inspect
      "<ComponentNode:#{@binding_id} #{@nodes.inspect}>"
    end
  end
end
