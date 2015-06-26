require 'spec_helper'

describe Volt::StateHelpers do
  describe "loaded_state"
  it 'should start loaded for page' do
    item = page._items.buffer
    expect(item.loaded_state).to eq(:loaded)
  end

  # TODO: because server side model loading is done synchronusly, we can't
  # test the

end