require 'spec_helper'

class ::TestIfBindingController < Volt::ModelController
  model :page
end

describe Volt::IfBinding do
  it 'should render an if' do
    dom = Volt::AttributeTarget.new(0)
    context = ::TestIfBindingController.new(volt_app)
    context._name = 'jimmy'

    branches = [
      [
        proc { _name == 'jimmy' },
        'main/if_true'
      ],
      [
        nil,
        'main/if_false'
      ]
    ]

    binding = ->(volt_app, target, context, id) do
      Volt::IfBinding.new(volt_app, target, context, 0, branches)
    end

    templates = {
      'main/main' => {
        'html' => 'hello <!-- $1 --><!-- $/1 -->',
        'bindings' => { 1 => [binding] }
      },
      'main/if_true' => {
        'html' => 'yes, true',
        'bindings' => {}
      },
      'main/if_false' => {
        'html' => 'no, false',
        'bindings' => {}
      }
    }

    volt_app = double('volt/app')
    expect(volt_app).to receive(:templates).and_return(templates).at_least(1).times

    Volt::TemplateRenderer.new(volt_app, dom, context, 'main', 'main/main')

    expect(dom.to_html).to eq('yes, true')

    context._name = 'bob'
    Volt::Computation.flush!
    expect(dom.to_html).to eq('no, false')
  end
end