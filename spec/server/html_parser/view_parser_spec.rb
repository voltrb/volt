require 'benchmark'
require 'volt/server/html_parser/view_parser'

describe ViewParser do
  it "should parse content bindings" do
    html = "<p>Some {content} binding, {name}</p>"
    
    view = ViewParser.new(html, "home/index/index/body")
    
    expect(view.templates).to eq({
      'home/index/index/body' => {
        'html' => '<p>Some <!-- $0 --><!-- $/0 --> binding, <!-- $1 --><!-- $/1 --></p>',
        'bindings' => {
          0 => ["lambda { |__p, __t, __c, __id| ContentBinding.new(__p, __t, __c, __id, Proc.new { content }) }"],
          1 => ["lambda { |__p, __t, __c, __id| ContentBinding.new(__p, __t, __c, __id, Proc.new { name }) }"]
        }
      }
    })
  end
  
  it "should parse if bindings" do
    html = <<-END
    <p>
      Some 
      {#if showing == :text}
        text
      {#elsif showing == :button}
        <button>Button</button>
      {#else}
        <a href="">link</a>
      {/}
    </p>
    END
    
    view = ViewParser.new(html, "home/index/index/body")
  
    expect(view.templates).to eq({
      "home/index/index/body/__template/0" => {
        "html" => "\n        text\n      ",
        "bindings" => {}
      },
      "home/index/index/body/__template/1" => {
        "html" => "\n        <button>Button</button>\n      ",
        "bindings" => {}
      },
      "home/index/index/body/__template/2" => {
        "html" =>"\n        <a href=\"\">link</a>\n      ",
        "bindings" => {}
      },
      "home/index/index/body" => {
        "html" =>"    <p>\n      Some \n      <!-- $0 --><!-- $/0 -->\n    </p>\n",
        "bindings" => {
          0 => [
            "lambda { |__p, __t, __c, __id| IfBinding.new(__p, __t, __c, __id, [[Proc.new { showing == :text }, \"home/index/index/body/__template/0\"], [Proc.new { showing == :button }, \"home/index/index/body/__template/1\"], [nil, \"home/index/index/body/__template/2\"]]) }"
          ]
        }
      }
    })
  end
  
  it "should handle nested if's" do
    html = <<-END
    <p>
      Some 
      {#if showing == :text}
        {#if sub_item}
          sub item text
        {/}
      {#else}
        other
      {/}
    </p>
    END
  
    view = ViewParser.new(html, "home/index/index/body")
  
    expect(view.templates).to eq({
      "home/index/index/body/__template/0/__template/0" => {
        "html" => "\n          sub item text\n        ",
        "bindings" => {}
      }, 
      "home/index/index/body/__template/0" => {
        "html" => "\n        <!-- $0 --><!-- $/0 -->\n      ",
        "bindings" => {
          0=>[
            "lambda { |__p, __t, __c, __id| IfBinding.new(__p, __t, __c, __id, [[Proc.new { sub_item }, \"home/index/index/body/__template/0/__template/0\"]]) }"
          ]
        }
      },
      "home/index/index/body/__template/1" => {
        "html"=>"\n        other\n      ",
        "bindings"=>{}
      },
      "home/index/index/body" => {
        "html" => "    <p>\n      Some \n      <!-- $0 --><!-- $/0 -->\n    </p>\n",
        "bindings"=> {
          0 => [
            "lambda { |__p, __t, __c, __id| IfBinding.new(__p, __t, __c, __id, [[Proc.new { showing == :text }, \"home/index/index/body/__template/0\"], [nil, \"home/index/index/body/__template/1\"]]) }"
          ]
        }
      }
    })
  end
  
  
  it "should parse each bindings" do
    html = <<-END
      <div class="main">
        {#each _items as item}
          <p>{item}</p>
        {/}
      </div>
    END
    
    view = ViewParser.new(html, "home/index/index/body")

    puts view.templates.inspect
    expect(view.templates).to eq({
      "home/index/index/body/_template/0" => {
        "html" => "\n          <p><!-- $0 --><!-- $/0 --></p>\n        ",
        "bindings" => {
          0 => [
            "lambda { |__p, __t, __c, __id| ContentBinding.new(__p, __t, __c, __id, Proc.new { item }) }"
          ]
        }
      },
      "home/index/index/body" => {
        "html" => "      <div class=\"main\">\n        <!-- $0 --><!-- $/0 -->\n      </div>\n",
        "bindings" => {
          0 => [
            "lambda { |__p, __t, __c, __id| EachBinding.new(__p, __t, __c, __id, Proc.new { _items }, \"item\", \"home/index/index/body/_template/0\") }"
          ]
        }
      }
    })
  end
  
end