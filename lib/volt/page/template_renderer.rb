require 'volt/page/bindings/base_binding'

module Volt
  class TemplateRenderer < BaseBinding
    attr_reader :context

    def initialize(volt_app, target, context, binding_name, template_name)
      super(volt_app, target, context, binding_name)

      @sub_bindings = []

      bindings = dom_section.set_content_to_template(volt_app, template_name)

      bindings.each_pair do |id, bindings_for_id|
        bindings_for_id.each do |binding|
          @sub_bindings << binding.call(volt_app, target, context, id)
        end
      end
    end

    def remove
      @sub_bindings.each(&:remove)
      @sub_bindings = []

      super
    end
  end
end
