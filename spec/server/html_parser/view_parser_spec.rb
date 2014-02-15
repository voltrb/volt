require 'benchmark'
require 'volt/server/html_parser/view_parser'

describe ViewParser do
  it "should parse content bindings" do
    html = "<p>Some {content} binding</p>"
    
    view = ViewParser.new(html, "home/index/index/body")
    
    expect(view.templates).to eq({
      'home/index/index/body' => {
        'html' => '<p>Some <!-- $0 --><!-- $/0 --> binding</p>',
        'bindings' => []
      }
    })
  end
end