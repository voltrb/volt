require 'spec_helper'

class ::TestSaveFailure < Volt::Model
  validate :name, length: 5
end

describe Volt::Buffer do
  it 'should let you pass a block that evaluates to the then of the promise' do
    buffer = the_page._items!.buffer

    count = 0
    result = buffer.save! do
      count += 1
    end

    expect(count).to eq(1)
    expect(result.class).to eq(Promise)
  end

  if RUBY_PLATFORM != 'opal'
    it 'should reject a failed save! with the errors object' do
      buffer = the_page._test_save_failures.buffer

      buffer._name = 'Ryan'

      then_count = 0
      fail_count = 0
      error = nil

      buffer.save!.then do
        then_count += 1
      end.fail do |err|
        fail_count += 1
        error = err
      end

      expect(then_count).to eq(0)
      expect(fail_count).to eq(1)
      expect(error.class).to eq(Volt::Errors)
      expect(error).to eq(name: ['must be at least 5 characters'])
    end
  end
end
