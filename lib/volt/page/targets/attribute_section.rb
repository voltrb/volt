# AttributeSection provides a place to render templates that
# will be placed as text into an attribute.

require 'volt/page/targets/base_section'

module Volt
  class AttributeSection < BaseSection
    def initialize(target, binding_name)
      @target       = target
      @binding_name = binding_name
    end

    def text=(text)
      set_content_and_rezero_bindings(text, {})
    end

    def html=(value)
      set_content_and_rezero_bindings(value, {})
    end

    # Takes in our html and bindings, and rezero's the comment names, and the
    # bindings.  Returns an updated bindings hash
    def set_content_and_rezero_bindings(html, bindings)
      if @binding_name == 'main'
        @target.html = html
      else
        @target.find_by_binding_id(@binding_name).html = html
      end

      bindings
    end

    def remove
      # TODO: is this getting run for no reason?
      node = @target.find_by_binding_id(@binding_name)
      node.remove if node
    end
  end
end
