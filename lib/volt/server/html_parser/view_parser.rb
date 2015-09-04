require 'volt/server/html_parser/sandlebars_parser'
require 'volt/server/html_parser/view_scope'
require 'volt/server/html_parser/if_view_scope'
require 'volt/server/html_parser/component_view_scope'
require 'volt/server/html_parser/view_handler'
require 'volt/server/html_parser/each_scope'
require 'volt/server/html_parser/textarea_scope'

module Volt
  class ViewParser
    attr_reader :templates, :links

    def initialize(html, template_path, sprockets_context=nil)
      @template_path = template_path

      handler = ViewHandler.new(template_path, sprockets_context)

      SandlebarsParser.new(html, handler)

      # Close out the last scope
      last_scope = handler.scope.last

      fail "Unclosed tag in:\n#{html}" unless last_scope

      last_scope.close_scope

      @templates = handler.templates
      @links     = handler.links
    end

    # Returns a parsed version of the data (useful for backend rendering
    # and testing)
    def data
      templates = @templates.deep_clone

      templates.each_pair do |name, value|
        if value['bindings']
          value['bindings'].each_pair do |number, binding|
            value['bindings'][number] = binding.map { |code| eval(code) }
          end
        end
      end

      templates
    end

    # Generate code for the view that can be evaled.
    def code(app_reference)
      code = ''
      templates.each_pair do |name, template|
        binding_code = []

        if template['bindings']
          template['bindings'].each_pair do |key, value|
            binding_code << "#{key.inspect} => [#{value.join(', ')}]"
          end
        end

        binding_code = "{#{binding_code.join(', ')}}"

        code << "#{app_reference}.add_template(#{name.inspect}, #{template['html'].inspect}, #{binding_code})\n"
      end

      code
    end
  end
end
