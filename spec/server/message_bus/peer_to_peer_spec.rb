require 'spec_helper'

unless RUBY_PLATFORM == 'opal'
  describe Volt::MessageBus::PeerToPeer do
    before do
      # Stub socket stuff
      allow_any_instance_of(Volt::MessageBus::PeerToPeer).to receive(:connect_to_peers).and_return(nil)
    end

  end
end