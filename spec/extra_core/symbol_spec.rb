if RUBY_PLATFORM == 'opal'
else
  require 'spec_helper'
  require 'volt/extra_core/symbol'

  describe Symbol do
    it 'should pluralize correctly' do
      expect(:car.pluralize).to eq(:cars)
    end

    it 'should singularize correctly' do
      expect(:cars.singularize).to eq(:car)
    end
  end
end
