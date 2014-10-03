require 'volt/page/targets/binding_document/html_node'
require 'volt/reactive/eventable'

# Component nodes contain an array of both HtmlNodes and ComponentNodes.
# Instead of providing a full DOM API, component nodes are the branch
# nodes and html nodes are the leafs.  This is all we need to produce
# the html from templates outside of a normal dom.
class ComponentNode < BaseNode
  include Eventable

  attr_accessor :parent, :binding_id, :nodes
  def initialize(binding_id=nil, parent=nil, root=nil)
    @nodes = []
    @binding_id = binding_id
    @parent = parent
    @root = root
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
    parts = html.split(/(\<\!\-\- \$\/?[0-9]+ \-\-\>)/).reject {|v| v == '' }

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

  def to_html
    str = []
    @nodes.each do |node|
      str << node.to_html
    end

    return str.join('')
  end

  def find_by_binding_id(binding_id)
    if @binding_id == binding_id
      return self
    end

    @nodes.each do |node|
      if node.is_a?(ComponentNode)
        val = node.find_by_binding_id(binding_id)
        return val if val
      end
    end

    return nil
  end

  def remove
    @nodes = []

    # puts "Component Node Removed"
    changed!

    # @binding_id = nil
  end

  def remove_anchors
    raise "not implemented"

    @parent.nodes.delete(self)

    changed!
    @parent = nil
    @binding_id = nil
  end

  def inspect
    "<ComponentNode:#{@binding_id} #{@nodes.inspect}>"
  end
end
