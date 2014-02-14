if RUBY_PLATFORM != 'opal'
  require 'volt/server/template_parser'

  describe TemplateParser do
    it 'should parse a doc' do
      template = <<-END
        <h1>Header {name}</h1>
  
        <p class="{paragraph_class}">{content}</p>
  
        <!-- Original Comment -->
        {#each some_array}
          <p>Line {some_name}</p>
        {/}
  
      END
      parser = TemplateParser.new(template, 'main')
    end
  
    it 'should parse nested' do
      template = <<-END
        <div class="test">
          <div class="test2">
            <h1>Header</h1>
          </div>
        </div>
      END
      parser = TemplateParser.new(template, 'main')
    end
  
    it "should parse nested bindings" do
      template = <<-END
      1{#if _a}2
        3{#if _b}4
          _a and _b
        {/}
      {/}
      END
      parser = TemplateParser.new(template, 'main')
    
      expect(parser.templates.keys).to eq(["main/body", "main/body/__template/1", "main/body/__template/0"])
      expect(parser.templates['main/body/__template/1']).to eq({"html"=>"4\n          _a and _b\n        ", "bindings"=>{}})
    end

    it "should parse templates in attributes" do
      template = <<-END
      <div class="{#if _model._is_cool}cool{/}">yes</div>
      END
      parser = TemplateParser.new(template, 'main')
    end
  end
end