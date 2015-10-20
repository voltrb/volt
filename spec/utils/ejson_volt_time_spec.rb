require 'spec_helper'
require 'volt/helpers/time'

describe Volt::EJSON, '.parse' do
  subject { Volt::EJSON }
  let(:epoch) { 135820576553 }
  let(:ruby_epoch) { epoch / 1000.0 }

  context 'parsing EJSON fields' do
    context 'VoltTime' do
      it 'parses proper $date EJSON fields to VoltTime' do
        parsed = subject.parse '{"a" : {"$date": 135820576553}}'

        expect(parsed['a']).to eq VoltTime.at(ruby_epoch)
        expect(parsed['a']).to be_a VoltTime
        
      end

      it 'parses nested EJSON date fields to VoltTime' do
        parsed = subject.parse '{"a" : {"b" : {"$date": 135820576553}}}'

        expect(parsed['a']['b']).to eq VoltTime.at(ruby_epoch)
        expect(parsed['a']['b']).to be_a VoltTime
      end

      it 'parses nested $dates within $escapes' do
        parsed = subject.parse(
          '{"a" : {"$escape": {"$date" : {"date" : {"$date": 135820576553}}}}}'
        )

        expect(parsed['a']['$date']['date']).to eq VoltTime.at(ruby_epoch)
        expect(parsed['a']['$date']['date']).to be_a VoltTime
      end

    end
  end
end

describe Volt::EJSON, '.stringify' do
  subject { Volt::EJSON }
  context 'marshaling dates' do
    let(:now) { VoltTime.now }
    let(:now_js_epoch) { now.to_i * 1_000 }

    it 'marshals when given a VoltTime' do
      stringified = subject.stringify when: now

      expect(stringified).to eq %({"when":{"$date":#{now_js_epoch}}})
    end

    it 'marshals nested VoltTimes' do
      stringified = subject.stringify how: { when: now }

      expect(stringified).to eq %({"how":{"when":{"$date":#{now_js_epoch}}}})
    end

    it 'marshals multiple VoltTimes' do
      stringified = subject.stringify when: now, then: now

      expect(stringified.gsub(' ', '')).to eq(
        %({"when":{"$date":#{now_js_epoch}},"then":{"$date":#{now_js_epoch}}})
      )
    end
  end
end
