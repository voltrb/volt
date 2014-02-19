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
    case tag_name[0]
    when '!'
      start_section(tag_name, attributes, unary)
    when ':'
      # Component
      last.add_component(tag_name, attributes, unary)
    else
      # Normal tag
      attributes = last.process_attributes(tag_name, attributes)
    
      attr_str = attributes.map {|v| "#{v[0]}=\"#{v[1]}\"" }.join(' ')
      if attr_str.size > 0
        # extra space
        attr_str = " " + attr_str
      end
      html << "<#{tag_name}#{attr_str}#{unary ? ' /' : ''}>"
    end
  end

  def end_tag(tag_name)
    html << "</#{tag_name}>"
  end
  
  def start_section(tag_name, attributes, unary)
    path = last.path
    # Start of section
    if @original_path
      # Close any previous sections
      last.close_scope
    else
      # This is the first time we've hit a section header, everything
      # outside of the headers should be removed
      @templates = {}
      @original_path = path
    end
    
    # Set the new path to include the section
    new_path = @original_path + '/' + tag_name[1..-1]
    @scope = [ViewScope.new(self, new_path)]
  end
  
end