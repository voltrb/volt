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
  
  it "should parse a single attribute binding" do
    html = <<-END
      <div class="{main_class}">
      </div>
    END
    
    view = ViewParser.new(html, "home/index/index/body")
    
    expect(view.templates).to eq({
      "home/index/index/body" => {
        "html" => "      <div id=\"0\">\n      </div>\n",
        "bindings" => {
          "0" => [
            "lambda { |__p, __t, __c, __id| AttributeBinding.new(__p, __t, __c, __id, \"class\", Proc.new { main_class }) }"
          ]
        }
      }
    })
  end
  
  it "should parse multiple attribute bindings in a single attribute" do
    html = <<-END
      <div class="start {main_class} {awesome_class} string">
      </div>
    END
    
    view = ViewParser.new(html, "home/index/index/body")
    
    expect(view.templates).to eq({
      "home/index/index/body/_rv1" => {
        "html" => "start <!-- $0 --><!-- $/0 --> <!-- $1 --><!-- $/1 --> string",
        "bindings" => {
          0 => [
            "lambda { |__p, __t, __c, __id| ContentBinding.new(__p, __t, __c, __id, Proc.new { main_class }) }"
          ],
          1 => [
            "lambda { |__p, __t, __c, __id| ContentBinding.new(__p, __t, __c, __id, Proc.new { awesome_class }) }"
          ]
        }
      },
      "home/index/index/body" => {
        "html" => "      <div id=\"0\">\n      </div>\n",
        "bindings" => {
          "0" => [
            "lambda { |__p, __t, __c, __id| AttributeBinding.new(__p, __t, __c, __id, \"class\", Proc.new { ReactiveTemplate.new(__p, __c, \"home/index/index/body/_rv1\") }) }"
          ]
        }
      }
    })
  end
  
  it "should parse a template" do
    html = <<-END
    {#template "/home/temp/path"}
    END
    
    view = ViewParser.new(html, "home/index/index/body")
    
    expect(view.templates).to eq({
      "home/index/index/body" => {
        "html" => "    <!-- $0 --><!-- $/0 -->\n",
        "bindings" => {
          0 => [
            "lambda { |__p, __t, __c, __id| TemplateBinding.new(__p, __t, __c, __id, Proc.new { [\"/home/temp/path\"] }) }"
          ]
        }
      }
    })
  end
  
  it "should parse components" do
    
  end
  
  it "should parse sections" do
    html = <<-END
    <!title>
      This text goes in the title
    
    <!body>
      <p>This text goes in the body</p> 
    END
    
    view = ViewParser.new(html, "home/index/index")
  end
  
end