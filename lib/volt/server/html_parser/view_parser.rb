require 'volt/server/html_parser/sandlebars_parser'


class ViewScope
  attr_accessor :html, :bindings, :path
  
  def initialize(path)
    @path = path
    @html = ''
    
    @bindings = {}
    @binding_number = 0
  end
  
  def add_binding(content)
    add_content_binding(content)
  end
  
  def add_content_binding(content)
		html = "<!-- $#{@binding_number} --><!-- $/#{@binding_number} -->"

		save_binding(@binding_number, "lambda { |__p, __t, __c, __id| ContentBinding.new(__p, __t, __c, __id, Proc.new { #{content} }) }")

		@binding_number += 1
		return html
  end
  
  def save_binding(number, code)
    @bindings[number] ||= []
    @bindings[number] << code
  end
  
end

class ViewHandler
  attr_reader :templates
  
  def html
    @scope.last.html
  end

  def initialize(scope)
    @scope = [scope]
    @templates = {}
  end
  
  def close_scope
    scope = @scope.pop
    
    @templates[scope.path] = {
      'html' => scope.html,
      'bindings' => scope.bindings
    }
  end

  def comment(comment)
    html << "<!--#{comment}-->"
  end

  def text(text)
    html << text
  end

  def binding(binding)
    html << @scope.last.add_binding(binding)
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


class ViewParser
  attr_reader :templates
  
  def initialize(html, template_path)
    @template_path = template_path

    main_scope = ViewScope.new(template_path)
    handler = ViewHandler.new(main_scope)
    
    SandlebarsParser.new(html, handler)
    
    handler.close_scope
    
    @templates = handler.templates
  end
end