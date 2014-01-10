class ReactiveTemplate
  include Events
  
  def initialize(context, template_path)
    @template_path = template_path
    @target = AttributeTarget.new
    @template = TemplateRenderer.new(@target, context, "main", template_path)
  end
  
  def event_added(event, scope_provider, first)
    if first && !@template_listener
      @template_listener = @target.on('changed') { update }
    end
  end
  
  def event_removed(event, last)
    if last && @template_listener
      @template_listener.remove
      @template_listener = nil
    end
  end
  
  # Render the template and get the current value
  def cur
    @target.to_html
  end
  
  # TODO: improve
  def skip_current_queue_flush
    true
  end
  
  
  def update
    trigger!('changed')
  end
  
end