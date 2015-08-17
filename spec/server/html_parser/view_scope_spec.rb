require 'spec_helper'

describe Volt::ViewScope do
  describe "methodize strings" do
    def methodize(str)
      Volt::ViewScope.methodize_string(str)
    end

    it 'should methodize a method without args' do
      code = methodize('something')
      expect(code).to eq('method(:something)')
    end

    it 'should methodize a method without args2' do
      code = methodize('something?')
      expect(code).to eq('method(:something?)')
    end

    it 'should methodize a method wit args1' do
      code = methodize('set_something(true)')
      expect(code).to eq('set_something(true)')
    end

    it 'should not methodize a method call with args' do
      code = methodize('something(item1, item2)')
      expect(code).to eq('something(item1, item2)')
    end

    it 'should not methodize on assignment' do
      code = methodize('params._something = 5')
      expect(code).to eq('params._something = 5')
    end

    it 'should not methodize on hash lookup' do
      code = methodize('hash[:something]')
      expect(code).to eq('hash[:something]')
    end

    it 'should not methodize on instance variables' do
      code = methodize('@something.call')
      expect(code).to eq('@something.call')
    end
  end
end