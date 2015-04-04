require 'json'
require 'volt'

module Volt
  # Renders responses for HttpController actions
  class HttpResponseRenderer
    @renderers = {}

    def self.renderers
      @renderers
    end

    # Register renderers.
    def self.register_renderer(name, content_type, proc)
      @renderers[name.to_sym] = { proc: proc, content_type: content_type }
    end

    # Default renderers for json and plain text
    register_renderer(:json, 'application/json', proc { |data| data.to_json })
    register_renderer(:plain, 'text/plain', proc { |data| data.to_s })

    # Iterate through @renderes to find a matching renderer for the given
    # content and call the given proc.
    # Other params fromt he content are returned as additional headers
    # Returns an empty string if no renderer could be found
    def render(content)
      content = content.symbolize_keys
      self.class.renderers.keys.each do |renderer_name|
        if content.key?(renderer_name)
          renderer = self.class.renderers[renderer_name]
          to_render = content.delete(renderer_name)
          rendered = renderer[:proc].call(to_render)
          return [rendered, content.merge(content_type: renderer[:content_type])]
        end
      end

      # If we couldn't find a renderer - just render an empty string
      ['', content_type: 'text/plain']
    end
  end
end
