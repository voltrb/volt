require 'spec_helper'

class ::TestSaveFailure < Volt::Model
  validate :name, length: 5
end

class ::TestChangedAttribute < Volt::Model
  before_save :change_attributes

  def change_attributes
    set('one', 1)
    set('two', 2)
  end
end

describe Volt::Buffer do
  it 'should let you pass a block that evaluates to the then of the promise' do
    buffer = the_page._items.buffer

    count = 0
    result = buffer.save! do
      count += 1
    end

    expect(count).to eq(1)
    expect(result.class).to eq(Promise)
  end

  it 'should clear the buffer\'s changed attributes after a save' do
    buffer = the_page._items.buffer

    buffer._name = 'Jimithy'

    expect(buffer.changed_attributes).to eq({name: [nil]})

    buffer.save!

    expect(buffer.changed_attributes).to eq({})
  end

  if RUBY_PLATFORM != 'opal'
    it 'should copy attributes back from the save_to model incase it changes them during save' do
      buffer = the_page._test_changed_attributes.buffer

      buffer.save!.sync
      expect(buffer.save_to.attributes.without(:id)).to eq({one: 1, two: 2})
      expect(buffer.attributes.without(:id)).to eq({one: 1, two: 2})
      expect(buffer.id).to eq(buffer.save_to.id)
    end

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
