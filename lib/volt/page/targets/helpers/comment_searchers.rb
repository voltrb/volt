module CommentSearchers

  def find_by_comment(text, in_node=`document`)
    node = nil

    %x{
      node = document.evaluate("//comment()[. = ' " + text + " ']", in_node, null, XPathResult.UNORDERED_NODE_ITERATOR_TYPE, null).iterateNext();
    }
    return node
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