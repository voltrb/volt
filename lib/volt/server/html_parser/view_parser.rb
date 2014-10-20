require 'volt/server/html_parser/sandlebars_parser'
require 'volt/server/html_parser/view_scope'
require 'volt/server/html_parser/if_view_scope'
require 'volt/server/html_parser/view_handler'
require 'volt/server/html_parser/each_scope'
require 'volt/server/html_parser/textarea_scope'

module Volt
  class ViewParser
    attr_reader :templates

    def initialize(html, template_path)
      @template_path = template_path

      handler = ViewHandler.new(template_path)

      SandlebarsParser.new(html, handler)

      # Close out the last scope
      handler.scope.last.close_scope

      @templates = handler.templates
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
  end
end
