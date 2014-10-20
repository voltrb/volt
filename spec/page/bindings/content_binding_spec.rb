require 'spec_helper'
require 'volt/page/bindings/content_binding'
require 'volt/page/targets/attribute_target'
require 'volt/page/targets/dom_section'
require 'volt/page/template_renderer'

describe Volt::ContentBinding do
  it 'should render the content in a content binding' do
    dom = Volt::AttributeTarget.new(0)
    context = { name: 'jimmy' }
    binding = Volt::ContentBinding.new(nil, dom, context, 0, proc { self[:name] })

    expect(dom.to_html).to eq('jimmy')
  end

  it 'should render with a template' do
    context = { name: 'jimmy' }
    binding = lambda { |page, target, context, id| Volt::ContentBinding.new(page, target, context, id, proc { self[:name] }) }

    templates = {
      'main/main' => {
        'html' => 'hello <!-- $1 --><!-- $/1 -->',
        'bindings' => { 1 => [binding] }
      }
    }

    page = double('volt/page')
    expect(page).to receive(:templates).and_return(templates)

    dom = Volt::AttributeTarget.new(0)

    Volt::TemplateRenderer.new(page, dom, context, 'main', 'main/main')

    expect(dom.to_html).to eq('hello jimmy')
  end
end
