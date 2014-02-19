class TextareaScope < ViewScope
  def initialize(handler, path, attributes)
    super(handler, path)
    puts "TEXTAREA SCOPE"

    @attributes = attributes
  end

  def add_binding(content)
    @html << "{#{content}}"
  end

  def close_scope(pop=true)
    html = @html
    @html = ''
    puts "HTML: #{html.inspect}"

    # Remove from the scope
    super

    attributes = @attributes
    attributes['value'] = html

    puts "ATTRS: #{attributes.inspect}"

    # Normal tag
    attributes = @handler.last.process_attributes('textarea', attributes)

    attr_str = attributes.map {|v| "#{v[0]}=\"#{v[1]}\"" }.join(' ')
    if attr_str.size > 0
      # extra space
      attr_str = " " + attr_str
    end
    @handler.last.html << "<textarea#{attr_str}></textarea>"

  end
end