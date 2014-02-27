module CommentSearchers

  def find_by_comment(text, in_node=`document`)
    node = nil

    %x{
      node = document.evaluate("//comment()[. = ' " + text + " ']", in_node, null, XPathResult.UNORDERED_NODE_ITERATOR_TYPE, null).iterateNext();
    }
    return node
  end
end