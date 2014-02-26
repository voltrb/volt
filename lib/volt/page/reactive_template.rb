class ReactiveTemplate
  include Events

  def initialize(page, context, template_path)
    # puts "New Reactive Template: #{context.inspect} - #{template_path.inspect}"
    @template_path = template_path
    @target = AttributeTarget.new
    @template = TemplateRenderer.new(page, @target, context, "main", template_path)
  end

  def event_added(event, scope_provider, first, first_for_event)
    if first && !@template_listener
      @template_listener = @target.on('changed') { update }
    end
  end

  def event_removed(event, last, last_for_event)
    if last && @template_listener
      @template_listener.remove
      @template_listener = nil
    end
  end

  # Render the template and get the current value
  def cur
    @target.to_html
  end

  def update
    trigger!('changed')
  end

  def remove
    @template.remove

    @template = nil
    @target = nil
    @template_path = nil
  end

end
