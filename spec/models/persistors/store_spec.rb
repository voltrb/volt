require 'spec_helper'
require 'volt/models'

describe Volt::Persistors::Store do
  it 'should tell the persistor when the model has changed' do
    persistor = double('volt/persistor')
    persistor_instance = double('volt/persistor instance')
    expect(persistor_instance).to receive(:loaded)
    expect(persistor).to receive(:new).and_return(persistor_instance)

    @model = Volt::Model.new({}, persistor: persistor)

    expect(persistor_instance).to receive(:changed)

    @model._attr = 'yes'
  end

  it 'should tell the persistor when something is added to an array model' do
    persistor = double('volt/persistor')
    persistor_instance = double('volt/persistor instance')
    expect(persistor_instance).to receive(:loaded)
    expect(persistor).to receive(:new).and_return(persistor_instance)
    expect(persistor_instance).to receive(:async?).and_return(false)

    @model = Volt::ArrayModel.new([1, 2, 3], persistor: persistor)

    expect(persistor_instance).to receive(:added).with(4, 3)

    @model << 4
  end

  it 'passes removed() to changed() by default' do
    model     = Volt::Model.new(abc: 123)
    persistor = Volt::Persistors::Store.new(model)
    expect(persistor.removed(:abc)).to eq(persistor.changed(:abc))
    model._abc = 456
    expect(persistor.removed(:abc)).to eq(persistor.changed(:abc))
  end

  unless RUBY_PLATFORM == 'opal'
    before do
      model = store._nesters.create(name: 'One').sync
      model._subone = {name: 'Two'}
    end

    it 'should reload a model with nested hash models' do
      model2 = store._nesters.first.sync

      expect(model2.to_h.without(:id, :subone)).to eq(name: 'One')
      expect(model2._subone.to_h.without(:id)).to eq(name: 'Two')
    end

    it 'should reload nested hash models with the same parent persistor' do
      model = store._nesters.first.sync
      expect(model.persistor).to eq(model._subone.persistor)
    end
  end

  unless RUBY_PLATFORM == 'opal'
    it 'should sync properties on the root' do
      store._name = 'Jim'
      store._name.then do |name|
        expect(name).to eq('Jim')
      end
    end
  end
end
