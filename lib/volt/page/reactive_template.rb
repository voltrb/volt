class ReactiveTemplate
  def initialize(page, context, template_path)
    @template_path = template_path
    @target = AttributeTarget.new(nil, nil, self)
    @template = TemplateRenderer.new(page, @target, context, "main", template_path)

  end

  def reactive?
    true
  end

  # Render the template and get the current value
  def cur
    @target.to_html
  end

  def update
    # TODORW:
    # trigger!('changed')
  end

  def remove
    @template.remove

    @template = nil
    @target = nil
    @template_path = nil
  end

end
