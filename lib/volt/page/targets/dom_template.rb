require 'volt/page/targets/helpers/comment_searchers'

# A dom template is used to optimize going from a template name to
# dom nodes and bindings.  It stores a copy of the template's parsed
# dom nodes, then when a new instance is requested, it updates the
# dom markers (comments) for new binding numbers and returns a cloneNode'd
# version of the dom nodes and the bindings.
class DomTemplate
  include CommentSearchers

  def initialize(page, template_name)
    template = page.templates[template_name]

    if template
      html = template['html']
      @bindings = template['bindings']
    else
      html = "<div>-- &lt; missing template #{template_name.inspect.gsub('<', '&lt;').gsub('>', '&gt;')} &gt; --</div>"
      @bindings = {}
    end

    @nodes = build_from_html(html)

    attach_bindings
  end

  # Returns the dom nodes and bindings
  def make_new
    bindings = update_binding_anchors!

    return `self.nodes.cloneNode(true)`
  end

  # Returns an unattached div with the nodes from the passed
  # in html.
  def build_from_html(html)
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
    return temp_div
  end

  # Finds each of the binding anchors in the temp dom, then stores a reference
  # to them so they can be quickly updated without using xpath to find them again.
  def track_binding_anchors
    @binding_anchors = {}

    # Loop through the bindings, find in nodes.
    bindings.each_pair do |name,binding|
      if name.is_a?(String)
        # Find the dom node for an attribute anchor
        node = nil
        %x{
          node = temp_div.querySelector('#' + name);
        }
        @binding_anchors[name] = node
      else
        # Find the dom node for a comment anchor
        start_comment = find_by_comment("$#{name}", temp_div)
        end_comment = find_by_comment("$/#{name}", temp_div)

        @binding_anchors[new_name] = [start_comment, end_comment]
      end
      end
    end
  end

  # Takes the binding_anchors and updates them with new numbers (comments and id's)
  # then returns the bindings updated to the new numbers.
  def update_binding_anchors!
    new_bindings = {}

    @binding_anchors.each_pair do |name, anchors|
      new_name = @@binding_number
      @@binding_number += 1

      if name.is_a?(String)
        if name[0..1] == 'id'
          # A generated id
          # update the id
          `anchors.setAttribute('id', 'id' + new_name);`

          new_bindings[new_name] = @bindings[name]
        else
          # Assume a fixed id, should not be updated
          # TODO: Might want to check the page to see if a node
          # with this id already exists and raise if it does.

          # Copy from existing binding
          new_bindings[name] = @bindings[name]
        end
      else
        start_comment, end_comment = anchors

        %x{
          start_comment.textContent = " $" + new_name + " ";
          end_comment.textContent = " $/" + new_name + " ";
        }

        new_bindings[new_name] = @bindings[name]
      end
    end

    return new_bindings
  end
end