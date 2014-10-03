require 'volt/server/html_parser/attribute_scope'

class ViewScope
  include AttributeScope

  attr_reader :html, :bindings
  attr_accessor :path, :binding_number

  def initialize(handler, path)
    @handler = handler
    @path = path

    @html = ''
    @bindings = {}
    @binding_number = 0
  end

  def <<(html)
    @html << html
  end

  def add_binding(content)
    case content[0]
    when '#'
  		command, *content = content.split(/ /)
  		content = content.join(' ')

      case command
      when '#if'
        add_if(content)
      when '#elsif'
        add_else(content)
      when '#else'
        if content.blank?
          add_else(nil)
        else
          raise "#else does not take a conditional #{content} was provided."
        end
      when '#each'
        add_each(content)
      when '#template'
        add_template(content)
      end
    when '/'
      # close binding
      close_scope
    else
      # content
      add_content_binding(content)
    end
  end

  def add_content_binding(content)
    @handler.html << "<!-- $#{@binding_number} --><!-- $/#{@binding_number} -->"
    save_binding(@binding_number, "lambda { |__p, __t, __c, __id| ContentBinding.new(__p, __t, __c, __id, Proc.new { #{content} }) }")
    @binding_number += 1
  end

  def add_if(content)
    # Add with path for if group.
    @handler.scope << IfViewScope.new(@handler, @path + "/__ifg#{@binding_number}", content)
    @binding_number += 1
  end

  def add_else(content)
    raise "#else can only be added inside of an if block"
  end

  def add_each(content)
    @handler.scope << EachScope.new(@handler, @path + "/__each#{@binding_number}", content)
  end

  def add_template(content)
    @handler.html << "<!-- $#{@binding_number} --><!-- $/#{@binding_number} -->"
    save_binding(@binding_number, "lambda { |__p, __t, __c, __id| TemplateBinding.new(__p, __t, __c, __id, #{@path.inspect}, Proc.new { [#{content}] }) }")

    @binding_number += 1
  end

  # Returns ruby code to fetch the parent. (by removing the last fetch)
  # TODO: Probably want to do this with AST transforms with the parser/unparser gems
  def parent_fetcher(getter)
    parent = getter.strip.gsub(/[.][^.]+$/, '')

    if parent.blank? || !getter.index('.')
      parent = 'self'
    end

    return parent
  end

  def last_method_name(getter)
    return getter.strip[/[^.]+$/]
  end

  def add_component(tag_name, attributes, unary)
    component_name = tag_name[1..-1].gsub(':', '/')

    @handler.html << "<!-- $#{@binding_number} --><!-- $/#{@binding_number} -->"

    data_hash = []
    attributes.each_pair do |name, value|
      parts = value.split(/(\{[^\}]+\})/).reject(&:blank?)
      binding_count = parts.count {|p| p[0] == '{' && p[-1] == '}'}

      # if this attribute has bindings
      if binding_count > 0
        if binding_count > 1
          # Multiple bindings
        elsif parts.size == 1 && binding_count == 1
          # A single binding
          getter = value[1..-2]
          data_hash << "#{name.inspect} => Proc.new { #{getter} }"

          setter = getter_to_setter(getter)
          data_hash << "#{(name + "=").inspect} => Proc.new { |val| #{setter} }"

          # Add an _parent fetcher.  Useful for things like volt-fields to get the parent model.
          parent = parent_fetcher(getter)

          # TODO: This adds some overhead, perhaps there is a way to compute this dynamically on the
          # front-end.
          data_hash << "#{(name + "_parent").inspect} => Proc.new { #{parent} }"

          # Add a _last_method property.  This is useful
          data_hash << "#{(name + "_last_method").inspect} => #{last_method_name(getter).inspect}"
        end
      else
        # String
        data_hash << "#{name.inspect} => #{value.inspect}"
      end
    end

    arguments = "#{component_name.inspect}, { #{data_hash.join(',')} }"

    save_binding(@binding_number, "lambda { |__p, __t, __c, __id| ComponentBinding.new(__p, __t, __c, __id, #{@path.inspect}, Proc.new { [#{arguments}] }) }")

    @binding_number += 1
  end

  def add_textarea(tag_name, attributes, unary)
    @handler.scope << TextareaScope.new(@handler, @path + "/__txtarea#{@binding_number}", attributes)
    @binding_number += 1

    # close right away if unary
    @handler.last.close_scope if unary
  end

  # Called when this scope should be closed out
  def close_scope(pop=true)
    if pop
      scope = @handler.scope.pop
    else
      scope = @handler.last
    end

    raise "template path already exists: #{scope.path}" if @handler.templates[scope.path]

    template = {
      'html' => scope.html
    }

    if scope.bindings.size > 0
      # Add the bindings if there are any
      template['bindings'] = scope.bindings
    end

    @handler.templates[scope.path] = template
  end

  def save_binding(binding_number, code)
    @bindings[binding_number] ||= []
    @bindings[binding_number] << code
  end
end
