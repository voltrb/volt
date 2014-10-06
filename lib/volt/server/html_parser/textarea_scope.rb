class TextareaScope < ViewScope
  def initialize(handler, path, attributes)
    super(handler, path)

    @attributes = attributes
  end

  def add_binding(content)
    @html << "{{#{content}}}"
  end

  def close_scope(pop=true)
    # Remove from the scope
    @handler.scope.pop

    attributes = @attributes

    if @html[/\{\{[^\}]+\}\}/]
      # If the html inside the textarea has a binding, process it as
      # a value attribute.
      attributes['value'] = @html
      @html = ''
    end

    # Normal tag
    attributes = @handler.last.process_attributes('textarea', attributes)

    @handler.last.html << "<textarea#{attribute_string(attributes)}>#{@html}</textarea>"

  end
end