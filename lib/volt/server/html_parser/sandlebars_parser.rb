require 'strscan'

class HTMLParseError < RuntimeError
end
# Parses html and bindings
# based on http://ejohn.org/files/htmlparser.js
#
# takes the html and a handler object that will have the following methods
# called as each is seen: comment, text, binding, start_tag, end_tag
#
# This is not a full html parser, but should cover most common cases.
class SandlebarsParser
  def self.truth_hash(array)
    hash = {}
    array.each {|v| hash[v] = true }

    return hash
  end

  # regex matchers
  START_TAG = /^<([-!\:A-Za-z0-9_]+)((?:\s+[\w\-]+(?:\s*=\s*(?:(?:"[^"]*")|(?:'[^']*')|[^>\s]+))?)*)\s*(\/?)>/
  END_TAG = /^<\/([-!\:A-Za-z0-9_]+)[^>]*>/
  ATTRIBUTES = /([-\:A-Za-z0-9_]+)(?:\s*=\s*(?:(?:"((?:\\.|[^"])*)")|(?:'((?:\\.|[^'])*)')|([^>\s]+)))?/

  # Types of elements
  BLOCK = truth_hash(%w{a address applet blockquote button center dd del dir div dl dt fieldset form frameset hr iframe ins isindex li map menu noframes noscript object ol p pre script table tbody td tfoot th thead tr ul})
  EMPTY = truth_hash(%w{area base basefont br col frame hr img input isindex link meta param embed})
  INLINE = truth_hash(%w{abbr acronym applet b basefont bdo big br button cite code del dfn em font i iframe img input ins kbd label map object q s samp script select small span strike strong sub sup textarea tt u var})
  CLOSE_SELF = truth_hash(%w{colgroup dd dt li options p td tfoot th thead tr})
  SPECIAL = truth_hash(%w{script style})

  FILL_IN_ATTRIBUTES = truth_hash(%w{checked compact declare defer disabled ismap multiple nohref noresize noshade nowrap readonly selected})

  def initialize(html, handler, file_path=nil)
    @html = StringScanner.new(html)
    @handler = handler
    @file_path = file_path

    @stack = []

    parse
  end

  def last
    @stack.last
  end

  def parse
    loop do
      if last && SPECIAL[last]
        # In a script or style tag, just look for the first end
        close_tag = "</#{last}>"
        body = @html.scan_until(/#{close_tag}/)
        body = body[0..((-1 * close_tag.size)-1)]

        body = body.gsub(/\<\!--(.*?)--\>/, "\\1").gsub(/\<\!\[CDATA\[(.*?)\]\]\>/, "\\1")

        text(body)

        end_tag(last, last)
      elsif @html.scan(/\<\!--/)
        # start comment
        comment = @html.scan_until(/--\>/)
        comment = comment[0..-4]

        @handler.comment(comment) if @handler.respond_to?(:comment)
      elsif (tag = @html.scan(START_TAG))
        tag_name = @html[1]
        rest = @html[2]
        unary = @html[3]

        start_tag(tag, tag_name, rest, unary)
      elsif @html.scan(END_TAG)
        tag_name = @html[1]

        end_tag(tag_name, tag_name)
      elsif (escaped = @html.scan(/\{\{\{(.*?)\}\}\}([^\}]|$)/))
        # Anything between {{{ and }}} is escaped and not processed (treaded as text)
        if escaped[-1] != '}'
          # Move back if we matched a new non } for close, skip if we hit the end
          @html.pos = @html.pos - 1
        end

        text(@html[1])
      elsif (binding = @html.scan(/\{\{/))
        # We are in text mode and matched the start of a binding
        start_binding
      elsif (text = @html.scan(/\{/))
        # A single { outside of a binding
        text(text)
      elsif (text = @html.scan(/(?:[^\<\{]+)/))
        # matched text up until the next html tag
        text(text)
      else
        # Nothing left
        break
      end
    end

    end_tag(nil, nil)
  end

  def text(text)
    @handler.text(text) if @handler.respond_to?(:text)
  end

  # Findings the end of a binding
  def start_binding
    binding = ''
    open_count = 1

    # scan until we reach a {{ or }}
    loop do
      binding << @html.scan_until(/(\{\{|\}\}|\n|\Z)/)

      match = @html[1]
      if match == '}}'
        # close
        open_count -= 1
        break if open_count == 0
      elsif match == '{{'
        # open more
        open_count += 1
      elsif match == "\n" || @html.eos?
        # Starting new tag, should be closed before this
        # or end of doc before closed binding
        raise_parse_error("unclosed binding: {#{binding.strip}")
      else
        raise "should not reach here"
      end
    end

    binding = binding[0..-3]
    @handler.binding(binding) if @handler.respond_to?(:binding)
  end

  def raise_parse_error(error)
    line_number = @html.pre_match.count("\n") + 1

    error_str = error + " on line: #{line_number}"
    error_str += " of #{@file_path}" if @file_path

    raise HTMLParseError, error_str
  end

  def start_tag(tag, tag_name, rest, unary)
    section_tag = tag_name[0] == ':' && tag_name[1] =~ /[A-Z]/

    tag_name = tag_name.downcase

    # handle doctype so we get it output exactly the same way
    if tag_name == '!doctype'
      @handler.text(tag) if @handler.respond_to?(:start_tag)
      return
    end

    # Auto-close the last inline tag if we started a new block
    if BLOCK[tag_name]
      if last && INLINE[last]
        end_tag(nil, last)
      end
    end

    # Some tags close themselves when a new one of themselves is reached.
    # ex, a tr will close the previous tr
    if CLOSE_SELF[tag_name] && last == tag_name
      end_tag(nil, tag_name)
    end

    unary = EMPTY[tag_name] || !unary.blank?

    # Section tag's are also unary
    unless unary || section_tag
      @stack.push(tag_name)
    end

    if @handler.respond_to?(:start_tag)
      attributes = {}

      # Take the rest string and extract the attributes, filling in any
      # "fill in" attribute values if not provided.
      rest.scan(ATTRIBUTES).each do |match|
        name = match[0]

        value = match[1] || match[2] || match[3] || FILL_IN_ATTRIBUTES[name] || ''

        attributes[name] = value
      end

      if section_tag
        @handler.start_section(tag_name, attributes, unary)
      else
        @handler.start_tag(tag_name, attributes, unary)
      end
    end
  end

  def end_tag(tag, tag_name)
    # If no tag name is provided, close all the way up
    new_size = 0

    if tag
      # Find the closest tag that closes.
      (@stack.size-1).downto(0) do |index|
        if @stack[index] == tag_name
          new_size = index
          break
        end
      end
    end

    if new_size >= 0
      if @handler.respond_to?(:end_tag)
        (@stack.size-1).downto(new_size) do |index|
          @handler.end_tag(@stack[index])
        end
      end

      @stack = @stack[0...new_size]
    end
  end
end