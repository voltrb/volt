if RUBY_PLATFORM == 'opal'
else
require 'benchmark'
require 'volt/server/html_parser/view_parser'

describe Volt::ViewParser do
  it 'should parse content bindings' do
    html = '<p>Some {{ content }} binding, {{ name }}</p>'

    view = Volt::ViewParser.new(html, 'main/main/main')

    expect(view.templates).to eq('main/main/main/body' => {
                                   'html' => '<p>Some <!-- $0 --><!-- $/0 --> binding, <!-- $1 --><!-- $/1 --></p>',
                                   'bindings' => {
                                     0 => ['lambda { |__p, __t, __c, __id| Volt::ContentBinding.new(__p, __t, __c, __id, Proc.new { content }) }'],
                                     1 => ['lambda { |__p, __t, __c, __id| Volt::ContentBinding.new(__p, __t, __c, __id, Proc.new { name }) }']
                                   }
                                 })
  end

  it 'should parse if bindings' do
    html = <<-END
    <p>
      Some
      {{ if showing == :text }}
        text
      {{ elsif showing == :button }}
        <button>Button</button>
      {{ else }}
        <a href="">link</a>
      {{ end }}
    </p>
    END

    view = Volt::ViewParser.new(html, 'main/main/main')

    expect(view.templates).to eq('main/main/main/body/__ifg0/__if0' => {
                                   'html' => "\n        text\n      "
                                 },
                                 'main/main/main/body/__ifg0/__if1' => {
                                   'html' => "\n        <button>Button</button>\n      "
                                 },
                                 'main/main/main/body/__ifg0/__if2' => {
                                   'html' => "\n        <a href=\"\">link</a>\n      "
                                 },
                                 'main/main/main/body' => {
                                   'html' => "    <p>\n      Some\n      <!-- $0 --><!-- $/0 -->\n    </p>\n",
                                   'bindings' => {
                                     0 => [
                                       "lambda { |__p, __t, __c, __id| Volt::IfBinding.new(__p, __t, __c, __id, [[Proc.new { showing == :text }, \"main/main/main/body/__ifg0/__if0\"], [Proc.new { showing == :button }, \"main/main/main/body/__ifg0/__if1\"], [nil, \"main/main/main/body/__ifg0/__if2\"]]) }"
                                     ]
                                   }
                                 })
  end

  it "should handle nested if's" do
    html = <<-END
    <p>
      Some
      {{ if showing == :text }}
        {{ if sub_item }}
          sub item text
        {{ end }}
      {{ else }}
        other
      {{ end }}
    </p>
    END

    view = Volt::ViewParser.new(html, 'main/main/main')

    expect(view.templates).to eq('main/main/main/body/__ifg0/__if0/__ifg0/__if0' => {
                                   'html' => "\n          sub item text\n        "
                                 },
                                 'main/main/main/body/__ifg0/__if0' => {
                                   'html' => "\n        <!-- $0 --><!-- $/0 -->\n      ",
                                   'bindings' => {
                                     0 => [
                                       "lambda { |__p, __t, __c, __id| Volt::IfBinding.new(__p, __t, __c, __id, [[Proc.new { sub_item }, \"main/main/main/body/__ifg0/__if0/__ifg0/__if0\"]]) }"
                                     ]
                                   }
                                 },
                                 'main/main/main/body/__ifg0/__if1' => {
                                   'html' => "\n        other\n      "
                                 },
                                 'main/main/main/body' => {
                                   'html' => "    <p>\n      Some\n      <!-- $0 --><!-- $/0 -->\n    </p>\n",
                                   'bindings' => {
                                     0 => [
                                       "lambda { |__p, __t, __c, __id| Volt::IfBinding.new(__p, __t, __c, __id, [[Proc.new { showing == :text }, \"main/main/main/body/__ifg0/__if0\"], [nil, \"main/main/main/body/__ifg0/__if1\"]]) }"
                                     ]
                                   }
                                 })
  end

  it 'should parse each bindings' do
    html = <<-END
      <div class="main">
        {{ _items.each do |item| }}
          <p>{{ item }}</p>
        {{ end }}
      </div>
    END

    view = Volt::ViewParser.new(html, 'main/main/main')

    expect(view.templates).to eq('main/main/main/body/__each0/__template/0' => {
                                   'html' => "\n          <p><!-- $0 --><!-- $/0 --></p>\n        ",
                                   'bindings' => {
                                     0 => [
                                       'lambda { |__p, __t, __c, __id| Volt::ContentBinding.new(__p, __t, __c, __id, Proc.new { item }) }'
                                     ]
                                   }
                                 },
                                 'main/main/main/body' => {
                                   'html' => "      <div class=\"main\">\n        <!-- $0 --><!-- $/0 -->\n      </div>\n",
                                   'bindings' => {
                                     0 => [
                                       "lambda { |__p, __t, __c, __id| Volt::EachBinding.new(__p, __t, __c, __id, Proc.new { _items }, \"main/main/main/body/__each0/__template/0\", \"item\", nil, nil) }"
                                     ]
                                   }
                                 })
  end

  it 'should parse each bindings with hash' do
    html = <<-END
      <div class="main">
        {{ _items.each do |key, value| }}
          <p>{{ value }}</p>
        {{ end }}
      </div>
    END

    view = Volt::ViewParser.new(html, 'main/main/main')

    expect(view.templates).to eq('main/main/main/body/__each0/__template/0' => {
                                   'html' => "\n          <p><!-- $0 --><!-- $/0 --></p>\n        ",
                                   'bindings' => {
                                     0 => [
                                       'lambda { |__p, __t, __c, __id| Volt::ContentBinding.new(__p, __t, __c, __id, Proc.new { value }) }'
                                     ]
                                   }
                                 },
                                 'main/main/main/body' => {
                                   'html' => "      <div class=\"main\">\n        <!-- $0 --><!-- $/0 -->\n      </div>\n",
                                   'bindings' => {
                                     0 => [
                                       "lambda { |__p, __t, __c, __id| Volt::EachBinding.new(__p, __t, __c, __id, Proc.new { _items }, \"main/main/main/body/__each0/__template/0\", \"value\", nil, \"key\") }"
                                     ]
                                   }
                                 })
  end

  it 'should parse a single attribute binding' do
    html = <<-END
      <div class="{{ main_class }}">
      </div>
    END

    view = Volt::ViewParser.new(html, 'main/main/main')

    expect(view.templates).to eq('main/main/main/body' => { 'html' => "      <div id=\"id0\">\n      </div>\n", 'bindings' => { 'id0' => ["lambda { |__p, __t, __c, __id| Volt::AttributeBinding.new(__p, __t, __c, __id, \"class\", Proc.new { main_class }, Proc.new { |val| self.main_class=(val) }) }"] } })
  end

  it 'should parse multiple attribute bindings in a single attribute' do
    html = <<-END
      <div class="start {{ main_class }} {{ awesome_class }} string">
      </div>
    END

    view = Volt::ViewParser.new(html, 'main/main/main')

    expect(view.templates).to eq('main/main/main/body/_rv1' => {
                                   'html' => 'start <!-- $0 --><!-- $/0 --> <!-- $1 --><!-- $/1 --> string',
                                   'bindings' => {
                                     0 => [
                                       'lambda { |__p, __t, __c, __id| Volt::ContentBinding.new(__p, __t, __c, __id, Proc.new { main_class }) }'
                                     ],
                                     1 => [
                                       'lambda { |__p, __t, __c, __id| Volt::ContentBinding.new(__p, __t, __c, __id, Proc.new { awesome_class }) }'
                                     ]
                                   }
                                 },
                                 'main/main/main/body' => {
                                   'html' => "      <div id=\"id0\">\n      </div>\n",
                                   'bindings' => {
                                     'id0' => [
                                       "lambda { |__p, __t, __c, __id| Volt::AttributeBinding.new(__p, __t, __c, __id, \"class\", Proc.new { Volt::StringTemplateRenderer.new(__p, __c, \"main/main/main/body/_rv1\") }) }"
                                     ]
                                   }
                                 })
  end

  it 'should parse a template' do
    html = <<-END
    {{ view "/home/temp/path" }}
    END

    view = Volt::ViewParser.new(html, 'main/main/main')

    expect(view.templates).to eq('main/main/main/body' => {
                                   'html' => "    <!-- $0 --><!-- $/0 -->\n",
                                   'bindings' => {
                                     0 => [
                                       "lambda { |__p, __t, __c, __id| Volt::ViewBinding.new(__p, __t, __c, __id, \"main/main/main/body\", Proc.new { [\"/home/temp/path\"] }) }"
                                     ]
                                   }
                                 })
  end

  it 'should setup a href multiple attribute binding correctly' do
    html = <<-END
    <a href="/{link_name}">Link</a>
    END

    view = Volt::ViewParser.new(html, 'main/main/main/body')

  end
  it 'should setup a href single attribute binding correctly' do
    html = <<-END
    <a href="{link_name}">Link</a>
    END

    view = Volt::ViewParser.new(html, 'main/main/main/body')
  end

  it 'should parse components' do
  end

  it 'should parse sections' do
    html = <<-END
    <:Title>
      This text goes in the title

    <:Body>
      <p>This text goes in the body</p>
    END

    view = Volt::ViewParser.new(html, 'main/main/main')

    expect(view.templates).to eq('main/main/main/title' => {
                                   'html' => "\n      This text goes in the title\n\n    "
                                 },
                                 'main/main/main/body' => {
                                   'html' => "\n      <p>This text goes in the body</p>\n"
                                 })
  end

  it 'should keep the html inside of a textarea if there are no bindings' do
    html = <<-END
    <textarea name="cool">some text in a textarea</textarea>
    END

    view = Volt::ViewParser.new(html, 'main/main/main')

    expect(view.templates).to eq('main/main/main/body' => {
                                   'html' => "    <textarea name=\"cool\">some text in a textarea</textarea>\n"
                                 })
  end

  it 'should setup bindings for textarea values' do
    html = <<-END
    <textarea name="cool">{{ awesome }}</textarea>
    END

    view = Volt::ViewParser.new(html, 'main/main/main')

    expect(view.templates).to eq('main/main/main/body' => { 'html' => "    <textarea name=\"cool\" id=\"id1\"></textarea>\n", 'bindings' => { 'id1' => ["lambda { |__p, __t, __c, __id| Volt::AttributeBinding.new(__p, __t, __c, __id, \"value\", Proc.new { awesome }, Proc.new { |val| self.awesome=(val) }) }"] } })
  end
end

end
