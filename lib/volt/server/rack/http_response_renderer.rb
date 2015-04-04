require 'json'

module Volt
  # Renders responses for HttpController
  class HttpResponseRenderer

    def render(val)
      if val.is_a?(Hash)
        if val.has_key?(:json)
          render_json(val[:json])
        elsif val.has_key?(:plain)
          render_plain_text(val[:plain])
        end
      else
        render_plain_text(val)
      end
    end

    private

    def render_json(json)
      [json.to_json, { content_type: 'application/json' }]
    end

    def render_plain_text(text)
      [text.to_s, { content_type: 'text/plain' }]
    end

  end
end