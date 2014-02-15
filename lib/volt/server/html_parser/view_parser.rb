require_relative 'sandlebars_parser'

class ViewScope
  attr_accessor :html
  
  def initialize(path)
    @path = path
    @html = ''
  end
end

class ViewHandler
  def html
    @scope.last
  end

  def initialize(scope)
    @scope = [scope]
  end

  def comment(comment)
    @scope.html << "<!--#{comment}-->"
  end

  def text(text)
    @scope.html << text
  end

  def binding(binding)
    @html << "{#{binding}}"
  end

  def start_tag(tag_name, attributes, unary)
    attr_str = attributes.map {|v| "#{v[0]}=\"#{v[1]}\"" }.join(' ')
    if attr_str.size > 0
      # extra space
      attr_str = " " + attr_str
    end
    @html << "<#{tag_name}#{attr_str}#{unary ? ' /' : ''}>"
  end

  def end_tag(tag_name)
    @html << "</#{tag_name}>"
  end
  
end


class ViewParser
  def initialize(html, template_path)
    SandlebarsParser.new
    
    @template_path = template_path
    
    
  end
end