require 'volt/page/bindings/base_binding'

class TemplateRenderer < BaseBinding
  attr_reader :context
  def initialize(page, target, context, binding_name, template_name)
    # puts "new template renderer: #{context.inspect} - #{binding_name.inspect}"
    super(page, target, context, binding_name)

    # puts "Template Name: #{template_name}"
    @template = @page.templates[template_name]
    @sub_bindings = []

    if @template
      html = @template['html']
      bindings = @template['bindings']
    else
      html = "<div>-- &lt; missing template #{template_name.inspect.gsub('<', '&lt;').gsub('>', '&gt;')} &gt; --</div>"
      bindings = {}
    end

    bindings = self.section.set_content_and_rezero_bindings(html, bindings)

    bindings.each_pair do |id,bindings_for_id|
      bindings_for_id.each do |binding|
        @sub_bindings << binding.call(page, target, context, id)
      end
    end
  end

  def remove
    # puts "Remove Template: #{self} - #{@sub_bindings.inspect}"

    # Remove all of the sub-bindings
    # @sub_bindings.each(&:remove)

    @sub_bindings.each do |binding|
      # puts "REMOVE: #{binding.inspect}"
      binding.remove
      # puts "REMOVED"
    end

    @sub_bindings = []

    super
  end
end
