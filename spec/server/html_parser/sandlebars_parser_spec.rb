if RUBY_PLATFORM == 'opal'
else
require 'spec_helper'
require 'benchmark'
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

  def binding(binding)
    @html << "{#{binding}}"
  end

  def start_tag(tag_name, attributes, unary)
    attr_str = attributes.map {|v| "#{v[0]}=\"#{v[1]}\"" }.join(' ')
    if attr_str.size > 0
      # extra space
      attr_str = " " + attr_str
    end
    @html << "<#{tag_name}#{attr_str}#{unary ? ' /' : ''}>"
  end

  def end_tag(tag_name)
    @html << "</#{tag_name}>"
  end
end

def parse_url(url)
  require 'open-uri'
  html = open("http://#{url}").read

  # html = File.read("/Users/ryanstout/Desktop/tests/#{url}1.html")

  File.open("/Users/ryanstout/Desktop/tests/#{url}1.html", 'w') {|f| f.write(html) }

  handler = HTMLHandler.new
  SandlebarsParser.new(html, handler)

  File.open("/Users/ryanstout/Desktop/tests/#{url}2.html", 'w') {|f| f.write(handler.html) }
end

describe SandlebarsParser do
  def test_html(html, match=nil)
    handler = HTMLHandler.new
    parser = SandlebarsParser.new(html, handler)

    expect(handler.html).to eq(match || html)
  end

  it "should handle a doctype" do
    html = "<!DOCTYPE html><p>text</p>"

    test_html(html)
  end

  it "should parse comments" do
    html = "<!-- my comment -->"
    test_html(html)
  end

  it "should handle text" do
    html = "some text, <!-- a comment -->, some more text"
    test_html(html)
  end

  it "should handle tags" do
    html = "<a name=\"cool\"></a>"
    test_html(html)
  end

  it "should close tags" do
    html = "<div><p>test</p>"
    match = "<div><p>test</p></div>"

    test_html(html, match)
  end

  it "should handle a script tag with html in it" do
    html = "<script><!-- some js code <a>cool</a> here --></script>"
    match = "<script> some js code <a>cool</a> here </script>"
    test_html(html, match)
  end

  it "should handle bindings" do
    html = "<p>some cool {text} is {awesome}</p>"
    test_html(html)
  end

  it "should handle bindings with nested { and }" do
    html = "<p>testing with {nested { 'binding stuff' }}</p>"
    test_html(html)
  end

  it "should raise an exception on an unclosed binding at the end of the document" do
    html = "<p>testing with {{nested"

    handler = HTMLHandler.new
    expect { SandlebarsParser.new(html, handler) }.to raise_error(HTMLParseError)
  end

  it "should raise an exception on an unclosed binding" do
    html = "<p>testing with {{nested </p>\n<p>ok</p>"

    handler = HTMLHandler.new
    expect { SandlebarsParser.new(html, handler) }.to raise_error(HTMLParseError)
  end

  it "should report the line number" do
    html = "\n\n<p>some paragraph</p>\n\n<p>testing with {{nested </p>\n<p>ok</p>"

    handler = HTMLHandler.new
    expect { SandlebarsParser.new(html, handler) }.to raise_error(HTMLParseError, "unclosed binding: {nested </p> on line: 5")
  end

  it "should handle a bunch of things" do
    html = <<-END
    <p class="some class">This is my text <a href="something.com">something.com</a></p>
    END

    test_html(html)
  end

  it "should not jump between script tags" do
    html = "\n<script>some text</script>\n\n<script>inside 2</script>\n"

    test_html(html)
  end

  it "should not jump bindings" do
    html = "<p>{some} text {binding}</p>"
    test_html(html)
  end

  it "should handle escaping things in a tripple escape" do
    html = "this is my {{{ tripple escape }}}"
    match = "this is my  tripple escape "
    test_html(html, match)
  end

  it "should let you escape { and }" do
    html = "should escape {{{{}}} and {{{}}}}"
    match = "should escape { and }"
    test_html(html, match)
  end

  it "should handle sandlebar tags" do
    html = "custom tag <:awesome name=\"yes\" />"
    test_html(html)
  end

  it "should keep the text after script" do
    html = "<ul><li>\n\n<script>\n\nsome js code\n\nmore\n\n</script>     \n     </li>   \n \n  </ul>"
    test_html(html)
  end

  it "should handle dashes in attributes" do
    html = "<form accept-charset=\"UTF-8\"></form>"
    test_html(html)
  end

  it "should handle conditional comments for IE" do
    html = "<!--[if ie6]>some ie only stuff<![endif]-->\n<br />"
    test_html(html)
  end

  it "should be fast" do
    html = File.read(File.join(File.dirname(__FILE__), 'sample_page.html'))
    handler = HTMLHandler.new
    time = Benchmark.measure do
      SandlebarsParser.new(html, handler)
    end

    # Less than 100ms
    expect(time.total).to be < 0.1
  end

  it "should parse nested components" do
    html = "custom tag <:awesome:cool name=\"yes\" />"
    test_html(html)
  end

  # it "should warn you when you over close tags" do
  #   html = "<div><p>test</p></div></div>"
  #
  #   handler = HTMLHandler.new
  #   expect { SandlebarsParser.new(html, handler) }.to raise_error(HTMLParseError)
  # end
end
end