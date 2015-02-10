require 'spec_helper'

class TestClassEventable
  include Volt::ClassEventable

  attr_reader :run_count

  def initialize
    @run_count = 0
  end

  on(:works) do
    ran_works
  end

  def ran_works
    @run_count += 1
  end

  def trigger_works_event!
    trigger!(:works, 20)
  end
end

describe Volt::ClassEventable do
  it 'does something' do
    test_ev = TestClassEventable.new

    expect(test_ev.run_count).to eq(0)
    test_ev.trigger_works_event!

    expect(test_ev.run_count).to eq(1)
    test_ev.trigger_works_event!

    expect(test_ev.run_count).to eq(2)
  end
end