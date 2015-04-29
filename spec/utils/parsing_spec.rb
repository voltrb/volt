require 'spec_helper'

describe Volt::Parsing do
  subject { Volt::Parsing }
  context 'surrounding encoding/decoding' do
    it 'does not mangle characters' do
      raw = ' !"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~''"'
      encoded = subject.encodeURI raw
      decoded = subject.decodeURI encoded

      expect(decoded).to eq raw
    end
  end
end
