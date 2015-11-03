# The tag node represents an html tag with a binding id in it.  It provides an
# api to change attribute values.

require 'volt/page/targets/binding_document/base_node'

module Volt
  class TagNode < BaseNode
    # We use some of the same parts from the sandlebars parser, but since this
    # has to ship to the client, we only take the parts we need.
    START_TAG  = /^<([-!\:A-Za-z0-9_]+)((?:\s+[\w\-]+(?:\s*=\s*(?:(?:"[^"]*")|(?:'[^']*')|[^>\s]+))?)*)\s*(\/?)>/
    ATTRIBUTES = /([-\:A-Za-z0-9_]+)(?:\s*=\s*(?:(?:"((?:\\.|[^"])*)")|(?:'((?:\\.|[^'])*)')|([^>\s]+)))?/

    attr_reader :tag_id
    attr_reader :attributes

    def initialize(html)
      tag = html.scan(START_TAG).first
      @start_tag = tag[0]
      @attributes = tag[1].scan(ATTRIBUTES).map do |match|
        name = match[0]
        value = match[1] || match[2] || match[3]

        # Store the tag's id for quick lookup
        if name == 'id'
          @tag_id = value
        end

        [name, value]
      end.to_h
      @end_tag = tag[2]
    end

    def to_html
      attr_str = @attributes.map do |key, value|
        "#{key}=\"#{value}\""
      end.join(' ')

      "<" + [@start_tag, attr_str, @end_tag].reject(&:blank?).join(' ') + ">"
    end
  end
end