# The yield binding renders the content of a tag which passes in

require 'volt/page/bindings/base_binding'
require 'volt/page/template_renderer'

module Volt
  class YieldBinding < BaseBinding
    def initialize(page, target, context, binding_name, binding_in_path, getter, content_template_path=nil)

    end
  end
end