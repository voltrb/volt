require 'volt/page/bindings/content_binding'
require 'volt/page/targets/attribute_target'


describe ContentBinding do
  it "should render the content in a content binding" do
    dom = AttributeTarget.new(0)
    context = {:name => 'jimmy'}
    binding = ContentBinding.new(dom, context, 0, Proc.new { self[:name] })
    
    expect(dom.to_html).to eq('jimmy')
  end
  
  it "should render with a template" do
    dom = AttributeTarget.new(0)
    context = {:name => 'jimmy'}
    binding = lambda {|target, context, id| ContentBinding.new(target, context, id, Proc.new { self[:name] }) }
    
    templates = {
      'home/index' => {
        'html' => 'hello <!-- $1 --><!-- $/1 -->',
        'bindings' => {1 => [binding]}
      }
    }
    
    TemplateRenderer.new(dom, context, 'main', 'home/index', templates)
    
    expect(dom.to_html).to eq('hello jimmy')
  end
end