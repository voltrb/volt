require 'spec_helper'

class ::BeforeCallbacksTest < Volt::Model
  before_validate :inc_validate_count
  before_create :inc_create_count
  before_save :inc_save_count
  before_update :inc_update_count
  attr_reader :validate_count, :create_count, :save_count, :update_count

  field :name, String

  def initialize(*)
    @validate_count = 0
    @create_count = 0
    @save_count = 0
    @update_count = 0
    super
  end

  def inc_validate_count
    @validate_count += 1
  end

  def inc_create_count
    @create_count += 1
  end

  def inc_save_count
    @save_count += 1
  end

  def inc_update_count
    @update_count += 1
  end
end


describe Volt::Models::Helpers::ChangeHelpers do
  # it 'should call before save before each save' do
  #   model = the_page._before_callbacks_tests.create({name: 'One'})

  #   expect(model.save_count).to eq(1)
  # end

  # it 'should call before_create before create' do
  #   model = the_page._before_callbacks_tests.create({name: 'One'})

  #   expect(model.create_count).to eq(1)
  # end

  # it 'should call before_update before update' do
  #   model = the_page._before_callbacks_tests.create({name: 'One'})
  #   expect(model.create_count).to eq(1)
  #   expect(model.update_count).to eq(0)

  #   model.name = 'New Name'
  #   expect(model.create_count).to eq(1)
  #   expect(model.update_count).to eq(1)

  #   model.name = 'Another name'
  #   expect(model.create_count).to eq(1)
  #   expect(model.update_count).to eq(2)
  #   expect(model.save_count).to eq(3)
  # end

  # # validation happens one extra time for the initial create
  # it 'should call before_validate before validate' do
  #   model = the_page._before_callbacks_tests.create({name: 'One'})
  #   expect(model.validate_count).to eq(2)

  #   model.name = 'New Name'
  #   expect(model.validate_count).to eq(3)
  # end

  # it 'should not call anything on a buffer' do
  #   model = the_page._before_callbacks_tests.buffer({name: 'One'})

  #   model.save!

  #   expect(model.create_count).to eq(0)
  #   expect(model.update_count).to eq(0)
  #   expect(model.save_count).to eq(0)
  #   expect(model.validate_count).to eq(0)

  # end
end
