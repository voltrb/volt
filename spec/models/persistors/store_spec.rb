require 'spec_helper'
require 'volt/models'

describe Volt::Persistors::Store do
  it 'should tell the persistor when the model has changed' do
    persistor = double('volt/persistor')
    persistor_instance = double('volt/persistor instance')
    expect(persistor_instance).to receive(:loaded)
    expect(persistor).to receive(:new).and_return(persistor_instance)

    @model = Volt::Model.new(nil, persistor: persistor)

    expect(persistor_instance).to receive(:changed)

    @model._attr = 'yes'
  end

  it 'should tell the persistor when something is added to an array model' do
    persistor = double('volt/persistor')
    persistor_instance = double('volt/persistor instance')
    expect(persistor_instance).to receive(:loaded)
    expect(persistor).to receive(:new).and_return(persistor_instance)

    @model = Volt::ArrayModel.new([1, 2, 3], persistor: persistor)

    expect(persistor_instance).to receive(:added).with(4, 3)

    @model << 4
  end
end
