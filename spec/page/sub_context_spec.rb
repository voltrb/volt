require 'spec_helper'
require 'volt/page/sub_context'

describe Volt::SubContext do
  it 'should respond_to correctly on locals' do
    sub_context = Volt::SubContext.new(name: 'Name')

    expect(sub_context.respond_to?(:name)).to eq(true)
    expect(sub_context.respond_to?(:missing)).to eq(false)
  end

  it 'should return correctly for missing methods on SubContext' do
    sub_context = Volt::SubContext.new(name: 'Name')

    expect(sub_context.send(:name)).to eq('Name')
    expect { sub_context.send(:missing) }.to raise_error(NoMethodError)
  end
end
