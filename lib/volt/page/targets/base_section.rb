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
    template = page.templates[template_name]

    if template
      html = template['html']
      bindings = template['bindings']
    else
      html = "<div>-- &lt; missing template #{template_name.inspect.gsub('<', '&lt;').gsub('>', '&gt;')} &gt; --</div>"
      bindings = {}
    end

    if is_a?(DomSection)
      # Lookup or cache
      temp_div = (@@template_cache[template_name] ||= build_from_html(html))
      temp_div = `temp_div.cloneNode(true)`
      # `console.log('temp div: ', temp_div)`
    else
      temp_div = nil
    end

    return set_content_and_rezero_bindings(html, bindings, temp_div)
  end

end
