require 'volt/page/bindings/base_binding'

class TemplateRenderer < BaseBinding
  attr_reader :context
  def initialize(target, context, binding_name, template_name)
    # puts "new template renderer: #{context.inspect} - #{binding_name.inspect}"
    super(target, context, binding_name)

    # puts "Template Name: #{template_name}"
    @template = $page.templates[template_name]
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
        @sub_bindings << binding.call(target, context, id)
      end
    end
    
    if @context.respond_to?(:section=)
      @context.section = self.section
    end
    
    if @context.respond_to?(:dom_ready)
      @context.dom_ready
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

    # Let the controller know we removed
    if @context.respond_to?(:dom_removed)
      @context.dom_removed
    end
    
    super
  end
  
  def remove_anchors
    section.remove_anchors
  end
end