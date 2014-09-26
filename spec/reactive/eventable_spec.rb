require 'spec_helper'
require 'volt/reactive/eventable'

class TestEventable
  include Eventable

  def trigger_works_event!
    trigger!('works', 20)
  end
end

describe Eventable do
  it 'should allow events to be bound with on' do
    test_eventable = TestEventable.new

    count = 0
    test_eventable.on('works') do |val|
      count += 1
      expect(val).to eq(20)
    end

    expect(count).to eq(0)
    test_eventable.trigger_works_event!
    expect(count).to eq(1)
  end

  it 'should allow events to be removed with .remove' do
    test_eventable = TestEventable.new

    count = 0
    listener = test_eventable.on('works') do
      count += 1
    end

    expect(listener.class).to eq(Listener)

    expect(count).to eq(0)
    test_eventable.trigger_works_event!
    expect(count).to eq(1)

    test_eventable.trigger_works_event!
    expect(count).to eq(2)

    listener.remove
    test_eventable.trigger_works_event!
    expect(count).to eq(2)
  end
end