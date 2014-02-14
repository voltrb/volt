require 'strscan'

# Parses html
# based on http://ejohn.org/files/htmlparser.js
class SandlebarsParser
  def self.truth_hash(array)
    hash = {}
    array.each {|v| hash[v] = true }
    
    return hash
  end


  # regex matchers
  START_TAG = /^<([-A-Za-z0-9_]+)((?:\s+\w+(?:\s*=\s*(?:(?:"[^"]*")|(?:'[^']*')|[^>\s]+))?)*)\s*(\/?)>/
  END_TAG = /^<\/([-A-Za-z0-9_]+)[^>]*>/
  ATTRIBUTES = /([-A-Za-z0-9_]+)(?:\s*=\s*(?:(?:"((?:\\.|[^"])*)")|(?:'((?:\\.|[^'])*)')|([^>\s]+)))?/

  # Types of elements
  EMPTY = truth_hash(%w{area base basefont br col frame hr img input isindex link meta param embed})
  INLINE = truth_hash(%w{a abbr acronym applet b basefont bdo big br button cite code del dfn em font i iframe img input ins kbd label map object q s samp script select small span strike strong sub sup textarea tt u var})
  CLOSE_SELF = truth_hash(%w{colgroup dd dt li options p td tfoot th thead tr})
  SPECIAL = truth_hash(%w{script style})
  
  FILL_IN_ATTRIBUTES = truth_hash(%w{checked compact declare defer disabled ismap multiple nohref noresize noshade nowrap readonly selected})
  
  def initialize(html, handler)
    @html = StringScanner.new(html)
    @handler = handler
    
    @stack = []
    
    parse
  end
  
  def last
    @stack.last
  end
  
  def parse
    loop do
      if @html.scan(/\<\!--/)
        # start comment
        comment = @html.scan_until(/--\>/)
        comment = comment[0..-4]
        
        @handler.comment(comment) if @handler.respond_to?(:comment)
      elsif @html.scan(START_TAG)
        tag_name = @html[1]
        
        
      elsif (text = @html.scan(/(?:[^\<]+)/))
        # matched text up until the next html tag
        @handler.text(text) if @handler.respond_to?(:text)
      else
        # Nothing left
        break
      end
    end
  end
end