require 'volt/server/html_parser/attribute_scope'

module Volt
  class ViewScope
    include AttributeScope

    attr_reader :html, :bindings
    attr_accessor :path, :binding_number

    def initialize(handler, path)
      @handler = handler
      @path    = path

      @html           = ''
      @bindings       = {}
      @binding_number = 0
    end

    def <<(html)
      @html << html
    end

    def add_end(_)
      close_scope
    end

    def add_binding(content)
      content = content.strip
      index = content.index(/[ \(]/)

      if index
        content_with_index(content, index)
      else
        content_with_no_index(content)
      end
    end

    def add_content_binding(content)
      @handler.html << "<!-- $#{@binding_number} --><!-- $/#{@binding_number} -->"
      save_binding(@binding_number, "lambda { |__p, __t, __c, __id| Volt::ContentBinding.new(__p, __t, __c, __id, Proc.new { #{content} }) }")
      @binding_number += 1
    end

    def add_if(content)
      # Add with path for if group.
      @handler.scope << IfViewScope.new(@handler, @path + "/__ifg#{@binding_number}", content)
      @binding_number += 1
    end

    def add_else(content)
      fail_msg = if content.blank?
        '#else can only be added inside of an if block'
      else
        "else does not take a conditional, #{content} was provided."
      end

      fail fail_msg
    end

    def add_elsif(content)
      add_else(content)
    end

    def add_each(content, with_index = false)
      @handler.scope << EachScope.new(@handler, @path + "/__each#{@binding_number}", content, with_index)
    end

    def add_each_with_index
      add_each(content, true)
    end

    def add_template(content)
      Volt.logger.warn('Deprecation warning: The template binding has been renamed to view.  Please update any views accordingly.')
      add_view(content)
    end

    def add_view(content)
      # Strip ( and ) from the outsides
      content = content.strip.gsub(/^\(/, '').gsub(/\)$/, '')

      @handler.html << "<!-- $#{@binding_number} --><!-- $/#{@binding_number} -->"
      save_binding(@binding_number, "lambda { |__p, __t, __c, __id| Volt::ViewBinding.new(__p, __t, __c, __id, #{@path.inspect}, Proc.new { [#{content}] }) }")

      @binding_number += 1
    end

    def add_yield(content=nil)
      # Strip ( and ) from the outsides
      content ||= ''
      content = content.strip.gsub(/^\(/, '').gsub(/\)$/, '')

      @handler.html << "<!-- $#{@binding_number} --><!-- $/#{@binding_number} -->"
      save_binding(@binding_number, "lambda { |__p, __t, __c, __id| Volt::YieldBinding.new(__p, __t, __c, __id, Proc.new { [#{content}] }) }")

      @binding_number += 1
    end

    # Returns ruby code to fetch the parent. (by removing the last fetch)
    # TODO: Probably want to do this with AST transforms with the parser/unparser gems
    def parent_fetcher(getter)
      parent = getter.strip.gsub(/[.][^.]+$/, '')

      if parent.blank? || !getter.index('.')
        parent = 'self'
      end

      parent
    end

    def last_method_name(getter)
      getter.strip[/[^.]+$/]
    end

    def add_component(tag_name, attributes, unary)
      @handler.scope << ComponentViewScope.new(@handler, @path + "/__component#{@binding_number}", tag_name, attributes, unary)

      @handler.last.close_scope if unary
    end

    def add_textarea(tag_name, attributes, unary)
      @handler.scope << TextareaScope.new(@handler, @path + "/__txtarea#{@binding_number}", attributes)
      @binding_number += 1

      # close right away if unary
      @handler.last.close_scope if unary
    end

    # Called when this scope should be closed out
    def close_scope(pop = true)
      if pop
        scope = @handler.scope.pop
      else
        scope = @handler.last
      end

      fail "template path already exists: #{scope.path}" if @handler.templates[scope.path]

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

    private

    def content_with_index(content, index)
      method, args = index_method_tuple(content, index)

      send(:"add_#{method}", args)
    end

    def content_with_no_index(content)
      if %w(end else yield).include? content
        send(:"add_#{content}", nil)
      else
        add_content_binding(content)
      end
    end

    def index_method_tuple(content, index)
      add_type = content[0...index]
      cases = %w(if elsif else view template yield)

      if cases.include? add_type
        [add_type, content[index..-1].strip]
      elsif content =~ /\.each/
        [content[/each(_with_index)?/], content]
      else
        ['content_binding', content]
      end
    end
  end
end
