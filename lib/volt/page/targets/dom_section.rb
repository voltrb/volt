require 'volt/page/targets/base_section'

class DomSection < BaseSection
  def initialize(binding_name)
    @start_node = find_by_comment("$#{binding_name}")
    @end_node = find_by_comment("$/#{binding_name}")
  end

  def find_by_comment(text, in_node=`document`)
    node = nil

    %x{
      node = document.evaluate("//comment()[. = ' " + text + " ']", in_node, null, XPathResult.UNORDERED_NODE_ITERATOR_TYPE, null).iterateNext();
    }
    return node
  end

  def text=(value)
    %x{
      this.$range().deleteContents();
      this.$range().insertNode(document.createTextNode(#{value}));
    }
  end

  def html=(value)
    set_content_and_rezero_bindings(value, {})
  end

  def remove
    range = self.range()

    %x{
      range.deleteContents();
    }
  end

  def remove_anchors
    %x{
      this.start_node.parentNode.removeChild(this.start_node);
      this.end_node.parentNode.removeChild(this.end_node);
    }
    @start_node = nil
    @end_node = nil
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
    range = self.range()

    %x{
      range.deleteContents();

      for (var i=nodes.length-1; i >= 0; i--) {
        var node = nodes[i];

        node.parentNode.removeChild(node);
        range.insertNode(node);
      }
    }
  end

  # Returns the nearest DOM node that contains all of the section.
  def container_node
    range = self.range()
    return `range.commonAncestorContainer`
  end

  # Takes in our html and bindings, and rezero's the comment names, and the
  # bindings.  Returns an updated bindings hash
  def set_content_and_rezero_bindings(html, bindings)
    sub_nodes = nil
    temp_div = nil

    %x{
      temp_div = document.createElement('div');
      var doc = jQuery.parseHTML(html);

      if (doc) {
        for (var i=0;i < doc.length;i++) {
          temp_div.appendChild(doc[i]);
        }
      }
    }

    new_bindings = {}
    # Loop through the bindings, and rezero.
    bindings.each_pair do |name,binding|
      new_name = @@binding_number

      if name.cur.is_a?(String)
        if name[0..1] == 'id'
        # Find by id
          %x{
            var node = temp_div.querySelector('#' + name);
            node.setAttribute('id', 'id' +new_name);
          }

          new_bindings["id#{new_name}"] = binding
        else
          # Assume a fixed id
          # TODO: We should raise an exception if this id is already on the page
          new_bindings[name] = binding
        end
      else
        # puts "----- #{name.inspect} - #{new_name}"
        # `console.log(temp_div);`
        # Change the comment ids
        start_comment = find_by_comment("$#{name}", temp_div)
        end_comment = find_by_comment("$/#{name}", temp_div)

        %x{
          start_comment.textContent = " $" + new_name + " ";
          end_comment.textContent = " $/" + new_name + " ";
        }

        new_bindings[new_name] = binding
      end


      @@binding_number += 1
    end


    children = nil
    %x{
      children = temp_div.childNodes;
    }

    # Update the nodes
    self.nodes = children

    %x{
      temp_div = null;
    }

    return new_bindings
  end

  def range
    return @range if @range

    range = nil
    %x{
      range = document.createRange();
      range.setStartAfter(this.start_node);
      range.setEndBefore(this.end_node);
    }

    @range = range

    return range
  end

  def inspect
    "<#{self.class.to_s}>"
  end

end
