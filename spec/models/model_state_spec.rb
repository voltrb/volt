# Models automatically unload if no dependencies are listening and they have not been .keep (kept)

if RUBY_PLATFORM != 'opal'
  require 'spec_helper'

  describe Volt::Model do
    it 'should stay loaded while a computaiton is watching some data' do
      expect(store._items.loaded_state).to eq(:not_loaded)

      comp = -> { store._items.size }.watch!

      # On the server models do a blocking load
      expect(store._items.loaded_state).to eq(:loaded)

      comp.stop

      Volt::Timers.flush_next_tick_timers!

      # Computation stopped listening, so the collection should unload and be set to
      # a dirty state
      expect(store._items.loaded_state).to eq(:dirty)
    end
  end
end