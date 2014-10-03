# StringTemplateRender are used to render a template to a string.  Call .html
# to get the string.  Be sure to call .remove when complete.
#
# StringTemplateRender will intellegently update the string in the same way
# a normal bindings will update the dom.

class StringTemplateRender
  def initialize(page, context, template_path)
    @dependency = Dependency.new

    @template_path = template_path
    @target = AttributeTarget.new(nil, nil, self)
    @template = TemplateRenderer.new(page, @target, context, "main", template_path)
  end

  # Render the template and get the current value
  def html
    @dependency.depend

    html = nil
    Computation.run_without_tracking do
      html = @target.to_html
    end

    return html
  end

  def changed!
    # if @dependency is missing, this template has been removed
    @dependency.changed! if @dependency
  end

  def remove
    @dependency.remove
    @dependency = nil

    Computation.run_without_tracking do
      @template.remove
      @template = nil
    end

    @target = nil
    @template_path = nil
  end

end
