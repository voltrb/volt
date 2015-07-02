require 'spec_helper'

class ::TestEachBindingController < Volt::ModelController
  model :page
end

describe Volt::EachBinding do
  it 'should render an each binding' do
    dom = Volt::AttributeTarget.new(0)
    context = ::TestEachBindingController.new(volt_app)
    context._items << {name: 'One'}
    context._items << {name: 'Two'}


    getter = Proc.new { context._items }
    variable_name = 'item'
    index_name = 'index'
    template_name = 'main/item'

    # Setup the each binding
    each_binding = ->(volt_app, target, context, id) do
      Volt::EachBinding.new(volt_app, target, context, id, getter,
                            variable_name, index_name, template_name)
    end

    # Setup a content binding to make sure its passing the right item
    content_binding = ->(volt_app, target, context, id) do
      Volt::ContentBinding.new(volt_app, target, context, id,
                               proc { item._name })
    end

    templates = {
      'main/main' => {
        'html' => 'hello <!-- $1 --><!-- $/1 -->',
        'bindings' => { 1 => [each_binding] }
      },
      'main/item' => {
        'html' => '<!-- $2 --><!-- $/2 -->, ',
        'bindings' => {
          2 => [content_binding]
        }
      }
    }

    volt_app = double('volt/app')
    expect(volt_app).to receive(:templates).and_return(templates).at_least(1).times

    Volt::TemplateRenderer.new(volt_app, dom, context, 'main', 'main/main')

    expect(dom.to_html).to eq('hello One, Two, ')

    context._items << {name: 'Three'}
    Volt::Computation.flush!
    expect(dom.to_html).to eq('hello One, Two, Three, ')
  end
end