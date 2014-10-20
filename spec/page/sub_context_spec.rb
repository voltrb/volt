require 'volt/page/sub_context'

describe Volt::SubContext do
  it 'should respond_to correctly on locals' do
    sub_context = Volt::SubContext.new(name: 'Name')

    expect(sub_context.respond_to?(:name)).to eq(true)
    expect(sub_context.respond_to?(:missing)).to eq(false)
  end
end
