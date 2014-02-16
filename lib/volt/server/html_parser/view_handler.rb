class ViewHandler
  attr_reader :templates, :scope
  
  def html
    last.html
  end
  
  def last
    @scope.last
  end

  def initialize(initial_path)
    @scope = [ViewScope.new(self, initial_path)]
    @templates = {}
  end

  def comment(comment)
    html << "<!--#{comment}-->"
  end

  def text(text)
    html << text
  end

  def binding(binding)
    @scope.last.add_binding(binding)
  end

  def start_tag(tag_name, attributes, unary)
    attr_str = attributes.map {|v| "#{v[0]}=\"#{v[1]}\"" }.join(' ')
    if attr_str.size > 0
      # extra space
      attr_str = " " + attr_str
    end
    html << "<#{tag_name}#{attr_str}#{unary ? ' /' : ''}>"
  end

  def end_tag(tag_name)
    html << "</#{tag_name}>"
  end
  
end