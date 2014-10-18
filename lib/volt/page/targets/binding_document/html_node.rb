require 'volt/page/targets/binding_document/base_node'

module Volt
  class HtmlNode < BaseNode
    def initialize(html)
      @html = html
    end

    def to_html
      @html
    end

    def inspect
      "<HtmlNode #{@html.inspect}>"
    end
  end
end
