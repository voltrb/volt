require 'spec_helper'

unless RUBY_PLATFORM == 'opal'
  describe 'validations block' do
    let(:model) { test_model_class.new }

    let(:test_model_class) do
      Class.new(Volt::Model) do
        validations do
          if _is_ready == true
            validate :name, length: 5
          end
        end
      end
    end

    let(:test_model_action_pass_class) do
      Class.new(Volt::Model) do
        validations do |action|
          # Only validation the name on update
          if action == :update
            validate :name, length: 5
          end
        end
      end
    end

    it 'should run conditional validations in the validations block' do
      a = test_model_class.new(name: 'Jo')

      a.validate!.sync
      expect(a.errors.size).to eq(0)

      a._is_ready = true
      a.validate!.sync

      expect(a.errors.size).to eq(1)
    end

    it 'should send the action name to the validations block' do
      jo = test_model_action_pass_class.new(name: 'Jo')

      jo.validate!.sync
      expect(jo.errors.size).to eq(0)

      store._people << jo

      jo.validate!.sync
      expect(jo.errors.size).to eq(1)

    end
  end
end