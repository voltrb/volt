require 'volt/page/targets/dom_template'

module Volt
  # Class to describe the interface for sections
  class BaseSection
    @@template_cache = {}

    def remove
      fail 'remove is not implemented'
    end

    def remove_anchors
      fail 'remove_anchors is not implemented'
    end

    def insert_anchor_before_end(binding_name)
      fail 'insert_anchor_before_end is not implemented'
    end

    def set_template
      fail 'set_template is not implemented'
    end

    def set_content_to_template(volt_app, template_name)
      if self.is_a?(DomSection)
        # DomTemplates are an optimization when working with the DOM (as opposed to other targets)
        dom_template = (@@template_cache[template_name] ||= DomTemplate.new(volt_app, template_name))

        set_template(dom_template)
      else
        template = volt_app.templates[template_name]

        if template
          html     = template['html']
          bindings = template['bindings']
        else
          html     = "<div>-- &lt; missing view or tag at #{template_name.inspect}, make sure it's component is included in dependencies.rb &gt; --</div>"
          bindings = {}
        end

        set_content_and_rezero_bindings(html, bindings)
      end
    end
  end
end
