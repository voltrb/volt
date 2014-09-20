class ReactiveTemplate
  def initialize(page, context, template_path)
    @dependency = Dependency.new

    @template_path = template_path
    @target = AttributeTarget.new(nil, nil, self)
    @template = TemplateRenderer.new(page, @target, context, "main", template_path)
    
  end

  # Render the template and get the current value
  def html
    @dependency.depend
    @target.to_html
  end
  
  def changed!
    @dependency.changed!
  end

  def remove
    @template.remove
    @dependency.remove
    @dependency = nil

    @template = nil
    @target = nil
    @template_path = nil
  end

end
