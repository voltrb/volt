# Class to describe the interface for sections
class BaseSection
  @@template_cache = {}

  def remove
    raise "not implemented"
  end

  def remove_anchors
    raise "not implemented"
  end

  def insert_anchor_before_end
    raise "not implemented"
  end

  def set_content_to_template(page, template_name)

    return set_content_and_rezero_bindings(html, bindings, temp_div)
  end

end
