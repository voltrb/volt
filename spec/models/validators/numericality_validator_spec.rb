require 'spec_helper'

describe Volt::Model do
  let(:buffer) { model.buffer }
  let(:model) { test_model_class.new }

  let(:test_model_class) do
    Class.new(Volt::Model) do
      validate :count, numericality: { gt: 5, lt: 10 }
    end
  end

  it 'should return errors for all failed validations' do
    model.validate!
    expect(model.errors).to eq(
      count: ['must be a number']
    )
  end

  it 'should show all fields in marked errors once saved' do
    buffer.save!

    expect(buffer.marked_errors.keys).to eq(
      [:count]
    )
  end

  describe 'builtin validations' do
    shared_examples_for 'a built in validation' do |field, message|
      specify do
        expect { model.mark_field! field }
          .to change { model.marked_errors }
          .from({}).to(field => [message])
      end
    end

    describe 'numericality' do
      message = 'must be a number'
      it_should_behave_like 'a built in validation', :count, message
    end
  end

  describe 'range conditions' do
    describe 'gt: and lt:' do
      let(:test_model_class) do
        Class.new(Volt::Model) do
          validate :count, numericality: { gt: 5, lt: 10 }
        end
      end

      describe 'gt:' do
        it 'fails for values less than or equal to specified' do
          buffer._count = 5
          buffer.validate!
          expect(buffer.errors).to eq(
            count: ['number must be greater than 5']
          )
        end

        it 'passes for values greater than specified' do
          buffer._count = 5.1
          buffer.validate!
          expect(buffer.errors).to eq({})
        end
      end

      describe 'lt:' do
        it 'fails for values greater than or equal to specified' do
          buffer._count = 10
          buffer.validate!
          expect(buffer.errors).to eq(
            count: ['number must be less than 10']
          )
        end

        it 'passes for values less than specified' do
          buffer._count = 9.9
          buffer.validate!
          expect(buffer.errors).to eq({})
        end
      end
    end

    describe 'gte: and lte:' do
      let(:test_model_class) do
        Class.new(Volt::Model) do
          validate :count, numericality: { gte: 5, lte: 10 }
        end
      end

      describe 'gte:' do
        it 'fails for values less than specified' do
          buffer._count = 4.9
          buffer.validate!
          expect(buffer.errors).to eq(
            count: ['number must be greater than or equal to 5']
          )
        end

        it 'passes for values equal to or greater than specified' do
          buffer._count = 5
          buffer.validate!
          expect(buffer.errors).to eq({})
        end
      end

      describe 'lte:' do
        it 'fails for values greater than specified' do
          buffer._count = 10.1
          buffer.validate!
          expect(buffer.errors).to eq(
            count: ['number must be less than or equal to 10']
          )
        end

        it 'passes for values equal to or less than specified' do
          buffer._count = 10
          buffer.validate!
          expect(buffer.errors).to eq({})
        end
      end
    end

    describe 'deprecated conditons' do
      let(:test_model_class) do
        Class.new(Volt::Model) do
          validate :count, numericality: { min: 5, max: 10 }
        end
      end

      describe 'min:' do
        it 'fails for values less than specified' do
          expect(Volt.logger).to receive(:warn).at_least(:once)
          buffer._count = 4.9
          buffer.validate!
          expect(buffer.errors).to eq(
            count: ['number must be greater than 5']
          )
        end

        it 'passes for values equal to or greater than specified' do
          expect(Volt.logger).to receive(:warn).at_least(:once)
          buffer._count = 5
          buffer.validate!
          expect(buffer.errors).to eq({})
        end
      end

      describe 'max:' do
        it 'fails for values greater than specified' do
          expect(Volt.logger).to receive(:warn).at_least(:once)
          buffer._count = 10.1
          buffer.validate!
          expect(buffer.errors).to eq(
            count: ['number must be less than 10']
          )
        end

        it 'passes for values equal to or less than specified' do
          expect(Volt.logger).to receive(:warn).at_least(:once)
          buffer._count = 10
          buffer.validate!
          expect(buffer.errors).to eq({})
        end
      end
    end

  end
end
