require 'volt/page/targets/binding_document/base_node'

class HtmlNode < BaseNode
  def initialize(html)
    @html = html
  end
  
  def to_html
    @html
  end
end