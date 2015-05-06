require 'volt/page/bindings/base_binding'
require 'volt/page/bindings/html_safe/string_extension'

module Volt
  class ContentBinding < BaseBinding
    HTML_ESCAPE_REGEXP = /[&"'><\n]/
    HTML_ESCAPE = { '&' => '&amp;',  '>' => '&gt;',   '<' => '&lt;', '"' => '&quot;', "'" => '&#39;', "\n" => "<br />\n" }

    def initialize(page, target, context, binding_name, getter)
      super(page, target, context, binding_name)

      # Listen for changes
      @computation = lambda do
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

      # The html safe check lets us know that if string can be rendered
      # directly as html
      unless html_safe
        # Escape any < and >, but convert newlines to br's, and fix quotes and
        value = html_escape(value)
      end

      # Assign the content
      dom_section.html = value
      # dom_section.text = value
    end

    def html_escape(str)
      # https://github.com/opal/opal/issues/798
      str.gsub(HTML_ESCAPE_REGEXP) do |char|
        HTML_ESCAPE[char]
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
