require 'volt/server/html_parser/sandlebars_parser'
require 'volt/server/html_parser/view_scope'
require 'volt/server/html_parser/if_view_scope'
require 'volt/server/html_parser/view_handler'
require 'volt/server/html_parser/each_scope'

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
end