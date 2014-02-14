require 'volt/server/html_parser/sandlebars_parser'

class HTMLHandler
  attr_reader :html
  
  def initialize
    @html = ''
  end
  
  def comment(comment)
    @html << "<!--#{comment}-->"
  end
  
  def text(text)
    @html << text
  end
end

describe SandlebarsParser do
  def test_html(html)
    handler = HTMLHandler.new
    parser = SandlebarsParser.new(html, handler)
    
    expect(handler.html).to eq(html)
  end
  
  it "should parse comments" do
    html = "<!-- my comment -->"
    test_html(html)
  end
  
  it "should handle text" do
    html = "some text, <!-- a comment -->, some more text"
    test_html(html)    
  end
end