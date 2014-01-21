require 'volt/server/scope'
require 'volt/server/if_binding_setup'
require 'nokogiri'

# TODO: The section_name that we're passing in should probably be
# abstracted out.  Possibly this whole thing needs a rewrite.

class Template
	attr_accessor :current_scope, :section_name

	def initialize(template_parser, section_name, template, scope=Scope.new)
    @binding_number = 0

		@template_parser = template_parser
    @section_name = section_name
		@template = template
    @scopes = [scope]
    @current_scope = @scopes.first
	end

	def html
    if @template.respond_to?(:name) && @template.name[0] == ':'
      # Don't return the <:section> tags
      return @template.children.to_html
    else
      # if @template.class == Nokogiri::XML::NodeSet
      #   result = ''
      #   @template.each do |node|
      #     result << node.to_html
      #   end
      # else
    		result = @template.to_html
      # end
      result
    end
	end


	def add_binding(node, content)
		if content[0] == '/'
			add_close_mustache(node)
		elsif content[0] == '#'
			command, *content = content.split(/ /)
			content = content.join(' ')

			case command
		  when '#template'
		    return add_template(node, content)
			when '#each'
				return add_each_binding(node, content)
			when '#if'
				return add_if_binding(node, content)
      when '#elsif'
        return add_else_binding(node, content)
      when '#else'
        if content.present?
          # TODO: improve error, include line/file
          raise "#else should not include a condition, use #elsif instead.  #{content} was passed as a condition."
        end
        
        return add_else_binding(node, nil)
			else
				# TODO: Handle invalid command
				raise "Invalid Command"
			end
		else
			# text binding
			return add_text_binding(content)
		end
	end

	def add_template(node, content, name='Template')
		html = "<!-- $#{@binding_number} --><!-- $/#{@binding_number} -->"

		@current_scope.add_binding(@binding_number, "lambda { |target, context, id| #{name}Binding.new(target, context, id, #{@template_parser.template_path.inspect}, Proc.new { [#{content}] }) }")

		@binding_number += 1
		return html
	end

	def add_each_binding(node, content)
		html = "<!-- $#{@binding_number} -->"
    
    content, variable_name = content.strip.split(/ as /)

    template_name = "#{@template_parser.template_path}/#{section_name}/__template/#{@binding_number}"
		@current_scope.add_binding(@binding_number, "lambda { |target, context, id| EachBinding.new(target, context, id, Proc.new { #{content} }, #{variable_name.inspect}, #{template_name.inspect}) }")

		# Add the node, the binding number, then store the location where the
		# bindings for this block starts.
		@current_scope = Scope.new(@binding_number)
		@scopes << @current_scope

		@binding_number += 1
		return html
	end

	def add_if_binding(node, content)
		html = "<!-- $#{@binding_number} -->"

    template_name = "#{@template_parser.template_path}/#{section_name}/__template/#{@binding_number}"
    if_binding_setup = IfBindingSetup.new
    if_binding_setup.add_branch(content, template_name)
    
		@current_scope.start_if_binding(@binding_number, if_binding_setup)

		# Add the node, the binding number, then store the location where the
		# bindings for this block starts.
		@current_scope = Scope.new(@binding_number)
		@scopes << @current_scope

		@binding_number += 1
		return html
	end
  
  def add_else_binding(node, content)
    html = add_close_mustache(node, false)
    
		html += "<!-- $#{@binding_number} -->"
    template_name = "#{@template_parser.template_path}/#{section_name}/__template/#{@binding_number}"
    
    @current_scope.current_if_binding[1].add_branch(content, template_name)
    
		# Add the node, the binding number, then store the location where the
		# bindings for this block starts.
		@current_scope = Scope.new(@binding_number)
		@scopes << @current_scope

		@binding_number += 1
    
    return html
  end

	def add_close_mustache(node, close_if=true)
		scope = @scopes.pop
		@current_scope = @scopes.last
    
    # Close an outstanding if binding (if it exists)
    @current_scope.close_if_binding! if close_if
    
		# Track that this scope was closed out
		@current_scope.add_closed_child_scope(scope)

		html = "<!-- $/#{scope.outer_binding_number} -->"

		return html
	end

	# When we find a binding, we pass it's content in here and replace it with
	# the return value
	def add_text_binding(content)
		html = "<!-- $#{@binding_number} --><!-- $/#{@binding_number} -->"

		@current_scope.add_binding(@binding_number, "lambda { |target, context, id| ContentBinding.new(target, context, id, Proc.new { #{content} }) }")

		@binding_number += 1
		return html
	end

  def setup_node_id(node)
    id = node['id']
		# First assign this node an id if it doesn't have one
		unless id
			id = node['id'] = "id#{@binding_number}"
			@binding_number += 1
		end
  end

  # Attribute bindings support multiple handlebar listeners
  # Exvoltle:
  #    <button click="{_primary} {_important}">...
  #
  # To accomplish this, we create a new listener from the existing ones in the Proc
  # that we pass to the binding when it is created.
	def add_attribute_binding(node, attribute, content)
		setup_node_id(node)
    
    if content =~ /^\{[^\{]+\}$/
      # Getter is the content inside of { ... }
      add_single_getter(node, attribute, content)
    else
      add_multiple_getters(node, attribute, content)
    end

	end
  
  def add_single_getter(node, attribute, content)
    if attribute == 'checked' || true
      # For a checkbox, we don't want to add
      getter = content[1..-2]
    else
      # Otherwise we should combine them
      # TODO: We should make .or handle assignment
      getter = "_tmp = #{content[1..-2]}.or('') ; _tmp.reactive_manager.setter! { |val| self.#{content[1..-2]} = val } ; _tmp"
    end
    
    @current_scope.add_binding(node['id'], "lambda { |target, context, id| AttributeBinding.new(target, context, id, #{attribute.inspect}, Proc.new { #{getter} }) }")
  end
  
  def add_multiple_getters(node, attribute, content)
    case attribute
    when 'checked', 'value'
      if parts.size > 1
        # Multiple ReactiveValue's can not be passed to value or checked attributes.
        raise "Multiple bindings can not be passed to a #{attribute} binding."
      end
    end
    
    reactive_template_path = add_reactive_template(content)
    
    @current_scope.add_binding(node['id'], "lambda { |target, context, id| AttributeBinding.new(target, context, id, #{attribute.inspect}, Proc.new { ReactiveTemplate.new(context, #{reactive_template_path.inspect}) }) }")
  end
  
  # Returns a path to a template for the content.  This can be passed
  # into ReactiveTemplate.new, along with the current context.
  def add_reactive_template(content)
    # Return a template path instead
    template_name = "__attribute/#{@binding_number}"
    full_template_path = "#{@template_parser.template_path}/#{section_name}/#{template_name}"
    @binding_number += 1
  
    attribute_template = Template.new(@template_parser, "#{section_name}/#{template_name}", Nokogiri::HTML::DocumentFragment.parse(content))
    @template_parser.add_template("#{section_name}/#{template_name}", attribute_template)
    attribute_template.start_walk
    attribute_template.pull_closed_block_scopes

    return full_template_path
  end

	def add_event_binding(node, attribute_name, content)
    setup_node_id(node)
    
    event = attribute_name[2..-1]
    
    if node.name == 'a'
      # For links, we need to add blank href to make it clickable.
      node['href'] ||= ''
    end

    @current_scope.add_binding(node['id'], "lambda { |target, context, id| EventBinding.new(target, context, id, #{event.inspect}, Proc.new {|event| #{content} })}")
  end

	def pull_closed_block_scopes(scope=@current_scope)
    if scope.closed_block_scopes
      scope.closed_block_scopes.each do |sub_scope|
        # Loop through any subscopes first, pull them in.
        pull_closed_block_scopes(sub_scope)
        
        # Grab everything between the start/end html comments
        start_node = find_by_comment("$#{sub_scope.outer_binding_number}")
        end_node = find_by_comment("$/#{sub_scope.outer_binding_number}")

        move_nodes_to_new_template(start_node, end_node, sub_scope)
      end
    end
  end


	def move_nodes_to_new_template(start_node, end_node, scope)
    # TODO: currently this doesn't handle spanning nodes within seperate containers.
    # so doing tr's doesn't work for some reason.
    
		start_parent = start_node.parent
		start_parent = start_parent.children if start_parent.is_a?(Nokogiri::HTML::DocumentFragment) || start_parent.is_a?(Nokogiri::XML::Element)
		start_index = start_parent.index(start_node) + 1

		end_parent = end_node.parent
		end_parent = end_parent.children if end_parent.is_a?(Nokogiri::HTML::DocumentFragment) || end_parent.is_a?(Nokogiri::XML::Element)
		end_index = end_parent.index(end_node) - 1

		move_nodes = start_parent[start_index..end_index]
		move_nodes.remove

    new_template = Template.new(@template_parser, section_name, move_nodes, scope)
    
    @template_parser.add_template("#{section_name}/__template/#{scope.outer_binding_number}", new_template)
	end


  def find_by_comment(name)
    return @template.xpath("descendant::comment()[. = ' #{name} ']").first
  end

	def start_walk
		walk(@template)
	end

	# We implement a dom walker that can walk down the dom and spit out output
	# html as we go
	def walk(node)
		case node.type
		when 1
			# html node
      walk_html_node(node)
		when 3
			# text node
      walk_text_node(node)
		end

		node.children.each do |child|
			walk(child)
		end
	end
  
  def walk_html_node(node)
    if node.name[0] == ':' && node.path.count('/') > 1
      parse_component(node)
    elsif node.name == 'textarea'
      parse_textarea(node)
    else
      parse_html_node(node)
    end
  end
  
  # We provide a quick way to render components with tags starting
  # with a :
  # Count the number of /'s in the path, if we are at the root node
  # we can ignore it, since this is the template its self.
  # TODO: Root node might not be the template if we parsed directly 
  # without a subtemplate specifier.  We need to find a good way to
  # parse only within the subtemplate.
  def parse_component(node)
    template_path = node.name[1..-1].gsub(':', '/')

    # Take the attributes and turn them into a hash
    attribute_hash = {}
    node.attribute_nodes.each do |attribute_node|
      content = attribute_node.value
      
      if !content.index('{')
        # passing in a string
        value = content.inspect
      elsif content =~ /^\{[^\}]+\}$/
        # Has one binding, just get it
        value = "Proc.new { #{content[1..-2]} }"
      else
        # Has multiple bindings, we need to render a template here
        attr_template_path = add_reactive_template(content)
        
        value = "Proc.new { ReactiveTemplate.new(context, #{attr_template_path.inspect}) }"
      end
      
      attribute_hash[attribute_node.name] = value
    end
    
    attributes_string = attribute_hash.to_a.map do |key, value|
      "#{key.inspect} => #{value}"
    end.join(', ')

    # Setup the arguments string, which goes to the TemplateBinding
    args_str = "#{template_path.inspect}"
    args_str << ", {#{attributes_string}}" if attribute_hash.size > 0

		new_html = add_template(node, args_str, 'Component')
    
    node.swap(new_html)#Nokogiri::HTML::DocumentFragment.parse(new_html))
  end
  
  def parse_textarea(node)
    # The contents of textareas should really be treated like a 
    # value= attribute.  So here we pull the content into a value attribute
    # if the textarea has bindings in the content.
    if node.inner_html =~ /\{[^\}]+\}/
      node[:value] = node.inner_html
      node.children.remove
    end
    
    parse_html_node(node)
  end
  
  def parse_html_node(node)
		node.attribute_nodes.each do |attribute_node|
		  if attribute_node.name =~ /^e\-/
        # We have an e- binding
        add_event_binding(node, attribute_node.name, attribute_node.value)

        # remove the attribute
        attribute_node.remove
			elsif attribute_node.value.match(/\{[^\}]+\}/)
        # Has bindings
				add_attribute_binding(node, attribute_node.name, attribute_node.value)

				# remove the attribute
				attribute_node.remove
			end
		end    
  end
  
  def walk_text_node(node)
		new_html = node.content.gsub(/\{([^\}]+)\}/) do |template_binding|
			add_binding(node, $1)
		end

    # puts "------! #{new_html.inspect} - #{node.class.inspect} - #{node.inspect}"

    # TODO: Broke here in jruby
    node.swap(new_html)# if new_html.blank?
    
    #Nokogiri::HTML::DocumentFragment.parse(new_html))
  end
end

class TemplateParser
	attr_accessor :dom, :bindings, :template_path

	def initialize(template, template_path)
		@templates = {}
    @template_path = template_path

    template_fragment = Nokogiri::HTML::DocumentFragment.parse(template)

    # Add templates for each section
    
    # Check for sections
    sections = []
    if template_fragment.children[0].name[0] == ':'
      template_fragment.children.each do |child|
        if child.is_a?(Nokogiri::XML::Element)
          sections << [child, child.name[1..-1]]
        end
      end
    else
      sections << [template_fragment, 'body']
    end
    
    sections.each do |section, name|
  		template = Template.new(self, name, section)
  		add_template(name, template)
  		template.start_walk
  		template.pull_closed_block_scopes
    end

	end

	def add_template(name, template)
    raise "Already defined at #{@template_path + '/' + name}" if @templates[@template_path + '/' + name]
		@templates[@template_path + '/' + name] = template
	end

	# Return the templates, but map the html from nokogiri to html
	def templates
		mapped = {}
		@templates.each_pair do |name, template|
			mapped[name] = {
				'html' => template.html,
				'bindings' => template.current_scope.bindings
			}
		end

		return mapped
	end

end
