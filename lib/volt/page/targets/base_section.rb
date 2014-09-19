require 'volt/page/targets/dom_template'

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
    if self.is_a?(DomSection)
      dom_template = (@@template_cache[template_name] ||= DomTemplate.new(page, template_name))

      return set_template(dom_template)
    else
      puts "RENDER: #{template_name}"
      template = page.templates[template_name]

      if template
        html = template['html']
        bindings = template['bindings']
      else
        html = "<div>-- &lt; missing template #{template_name.inspect.gsub('<', '&lt;').gsub('>', '&gt;')} &gt; --</div>"
        bindings = {}
      end

      return set_content_and_rezero_bindings(html, bindings)
    end
  end

end
