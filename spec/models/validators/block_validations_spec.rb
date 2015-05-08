require 'spec_helper'

describe 'validations block' do
  let(:model) { test_model_class.new }

  let(:test_model_class) do
    Class.new(Volt::Model) do
      validations do
        puts "RUN VALIDATIONS BLOCK: #{self.inspect}"
        if _is_ready == true
          puts "IS READY"
          validate :name, length: 5
        end
        puts "AFTER"
      end
    end
  end

  it 'should run conditional validations in the validations block' do
    puts 'A'
    a = test_model_class.new(name: 'Jo')

    puts 'B'
    a.validate!.sync

    puts 'C'
    expect(a.errors.size).to eq(0)


    puts 'D'
    a._is_ready = true
    a.validate!.sync

    puts "#{a.errors.inspect}"
    expect(a.errors.size).to eq(1)
  end
end