require 'spec_helper'
require 'volt/reactive/eventable'

class TestEventable
  include Volt::Eventable
  attr_reader :events_removed

  def initialize
    @events_removed = []
  end

  def event_removed(event, last, last_for_event)
    @events_removed.push(event => [last, last_for_event])
  end

  def trigger_works_event!
    trigger!('works', 20)
  end
end

describe Volt::Eventable do
  let(:test_eventable) { TestEventable.new }

  it 'should allow events to be bound with on' do
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
    count = 0
    listener = test_eventable.on('works') do
      count += 1
    end

    expect(listener.class).to eq(Volt::Listener)

    expect(count).to eq(0)
    test_eventable.trigger_works_event!
    expect(count).to eq(1)

    test_eventable.trigger_works_event!
    expect(count).to eq(2)

    listener.remove
    test_eventable.trigger_works_event!
    expect(count).to eq(2)
  end

  it 'should allow multiple events' do
    called = false
    listener = test_eventable.on(:broken, :works) do |arg|
      expect(arg).to eq(20)
      called = true
    end

    test_eventable.trigger_works_event!
    expect(called).to eq(true)

    # Stop the listener
    listener.remove
    called = false

    # Shouldn't run now
    test_eventable.trigger_works_event!
    expect(called).to eq(false)
  end

  it 'Shows object ID and events when inspected' do
    tested = TestEventable.new.on("test") { nil }
    inspected = tested.inspect
    expect(inspected).to include(tested.object_id.to_s)
    expect(inspected).to include(tested.events.first.to_s)
  end

  it 'calls event_removed on the class included on removal of event' do
    listener = test_eventable.on("test") { nil }
    listener.remove
    expect(test_eventable.events_removed).to include(test: [true, true])
  end
end
