require 'volt/page/targets/binding_document/component_node'

describe ComponentNode do
  before do
    html = <<-END
    <!-- $0 -->Before  <!-- $1 -->Inside<!-- $/1 -->  After<!-- $/0 -->
    END
    
    @component = ComponentNode.new
    @component.html = html
  end
  
  it "should find a component from a binding id" do
    expect(@component.find_by_binding_id(1).to_html).to eq('Inside')
    expect(@component.find_by_binding_id(0).to_html).to eq('Before  Inside  After')
    
  end
end