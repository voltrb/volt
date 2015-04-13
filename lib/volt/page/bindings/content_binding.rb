require 'volt/page/bindings/base_binding'
require 'volt/page/bindings/html_safe/string_extension'

module Volt
  class ContentBinding < BaseBinding
    def initialize(page, target, context, binding_name, getter)
      # puts "New Content Binding: #{self.inspect}"
      super(page, target, context, binding_name)

      # Listen for changes
      @computation = -> do
        begin
          res = @context.instance_eval(&getter)
        rescue => e
          Volt.logger.error("ContentBinding Error: #{e.inspect}")
          ''
        end
      end.watch_and_resolve! do |result|
        update(result)
      end
    end

    def update(value)
      value = (value || '').to_s unless value.is_a?(String)
      html_safe = value.html_safe?

      # Exception values display the exception as a string
      value = value.to_s

      # Update the html in this section
      # TODO: Move the formatter into another class.

      # The html safe check lets us know that the string can be rendered
      # directly as html
      if html_safe
        dom_section.html = value
      else
        value = value.gsub("\n", "<br />\n")
        dom_section.text = value
      end
    end

    def remove
      if @computation
        @computation.stop
        @computation = nil
      end

      super
    end
  end
end
