require 'volt/page/targets/binding_document/component_node'

describe Volt::ComponentNode do
  before do
    html = <<-END
    <!-- $0 -->Before  <!-- $1 -->Inside<!-- $/1 -->  After<!-- $/0 -->
    END

    @component = Volt::ComponentNode.new
    @component.html = html
  end

  it 'should find a component from a binding id' do
    expect(@component.find_by_binding_id(1).to_html).to eq('Inside')
    expect(@component.find_by_binding_id(0).to_html).to eq('Before  Inside  After')

  end

  # it "should render if blocks" do
  #   view = <<-END
  #   {#if _show}show{/} title
  #   END
  #
  #   page = Page.new
  #
  #   template = ViewParser.new(view, main/main/main/index/index/title')
  #
  #   page.add_template
  # end
end
