require 'spec_helper'
require 'volt/controllers/model_controller'

class BaseTestActions
  include Volt::LifecycleCallbacks

  setup_action_helpers_in_class(:before_action, :after_action)
end

class TestActionsBlocks < BaseTestActions
  before_action do
    @ran_before1 = true
  end

  before_action do
    @ran_before2 = true
  end

  attr_reader :ran_before1, :ran_before2
end

class TestActionsSymbolsBase < BaseTestActions
  attr_accessor :ran_one, :ran_two

  def run_one
    @ran_one = true
  end

  def run_two
    @ran_two = true
  end
end

class TestActionsSymbols < TestActionsSymbolsBase
  before_action :run_one
  before_action :run_two
end

class TestActions2 < BaseTestActions
end

class TestActionsMultipleSymbols < TestActionsSymbolsBase
  before_action :run_one, :run_two
end

# Runs three actions, stopping the chanin after one
class TestStopCallbacks < BaseTestActions
  before_action :run_one, :run_two, :run_three
  attr_accessor :ran_one, :ran_two, :ran_end_of_two, :ran_three

  def run_one
    @ran_one = true
  end

  def run_two
    @ran_two = true
    stop_chain
    @ran_end_of_two = true
  end

  def run_three
    @ran_three = true
  end
end

class TestNoCallbacks < BaseTestActions
end

class TestOnlyCallbacks < TestActionsSymbolsBase
  before_action :run_one, :run_two, only: [:new]
end

describe Volt::LifecycleCallbacks do
  it 'should trigger before actions via blocks' do
    test_class = TestActionsBlocks.new

    expect(test_class.ran_before1).to eq(nil)
    expect(test_class.ran_before2).to eq(nil)

    test_class.run_callbacks(:before_action, :index)

    expect(test_class.ran_before1).to eq(true)
    expect(test_class.ran_before2).to eq(true)
  end

  it 'should trigger before actions via symbols' do
    test_class = TestActionsSymbols.new

    expect(test_class.ran_one).to eq(nil)
    expect(test_class.ran_two).to eq(nil)

    test_class.run_callbacks(:before_action, :index)

    expect(test_class.ran_one).to eq(true)
    expect(test_class.ran_two).to eq(true)
  end

  it 'should raise an exception if no symbol or block is provided' do
    expect do
      TestActions2.before_action
    end.to raise_error(RuntimeError, 'No callback symbol or block provided')
  end

  it 'should support multiple symbols passed an action helper' do
    test_class = TestActionsMultipleSymbols.new

    expect(test_class.ran_one).to eq(nil)
    expect(test_class.ran_two).to eq(nil)

    result = test_class.run_callbacks(:before_action, :index)
    expect(result).to eq(false)

    expect(test_class.ran_one).to eq(true)
    expect(test_class.ran_two).to eq(true)
  end

  it 'should stop the chain when #stop_chain is called and return false from #run_callbacks' do
    test_class = TestStopCallbacks.new

    result = test_class.run_callbacks(:before_action, :index)
    expect(result).to eq(true)

    expect(test_class.ran_one).to eq(true)
    expect(test_class.ran_two).to eq(true)
    expect(test_class.ran_end_of_two).to eq(nil)
    expect(test_class.ran_three).to eq(nil)
  end

  it 'should call without any callbacks' do
    test_class = TestNoCallbacks.new

    result = test_class.run_callbacks(:before_action, :index)
    expect(result).to eq(false)
  end

  it 'should follow only limitations' do
    test_only = TestOnlyCallbacks.new

    test_only.run_callbacks(:before_action, :index)
    expect(test_only.ran_one).to eq(nil)
    expect(test_only.ran_two).to eq(nil)

    test_only.run_callbacks(:before_action, :new)
    expect(test_only.ran_one).to eq(true)
    expect(test_only.ran_two).to eq(true)
  end
end
