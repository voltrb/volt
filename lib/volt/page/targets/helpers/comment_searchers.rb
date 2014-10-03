module CommentSearchers
  if RUBY_PLATFORM == 'opal'
    NO_XPATH = `!!window._phantom || !document.evaluate`
  else
    NO_XPATH = false
  end

  def find_by_comment(text, in_node=`document`)
    if NO_XPATH
      return find_by_comment_without_xml(text, in_node)
    else
      node = nil

      %x{
        node = document.evaluate("//comment()[. = ' " + text + " ']", in_node, null, XPathResult.UNORDERED_NODE_ITERATOR_TYPE, null).iterateNext();
      }
      return node
    end
  end

  # PhantomJS does not support xpath in document.evaluate
  def find_by_comment_without_xml(text, in_node)
    match_text = " #{text} "
    %x{
      function walk(node) {
        if (node.nodeType === 8 && node.nodeValue === match_text) {
          return node;
        }

        var children = node.childNodes;
        if (children) {
          for (var i=0;i < children.length;i++) {
            var matched = walk(children[i]);
            if (matched) {
              return matched;
            }
          }
        }

        return null;
      }


      return walk(in_node);

    }
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
end