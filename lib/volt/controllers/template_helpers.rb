module Volt
  module TemplateHelpders
    module ClassMethods
      def template(name, template, bindings)
        @templates[name] = { 'html' => template, 'bindings' => bindings }
      end
    end

    def self.included(base)
      # Setup blank templates class variable
      base.class_attribute :__templates
      base.__templates = {}

      base.send :extend, ClassMethods
    end
  end


end