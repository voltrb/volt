require 'spec_helper'

describe Volt::EJSON, '.parse' do
  subject { Volt::EJSON }
  let(:epoch) { 135820576553 }
  let(:ruby_epoch) { epoch / 1000.0 }

  context 'safe escaping' do
    it 'does not parse date objects with invalid values' do
      parsed = subject.parse '{"a" : {"$escape" : {"$date" : "something"}}}'

      expect(parsed).to eq('a' => { '$date' => 'something' })
    end

    it 'only escapes one level down' do
      parsed = subject.parse %({"$escape": {"$date": {"$date": #{epoch}}}})

      expect(parsed).to eq('$date' => Time.at(ruby_epoch))
    end
  end

  context 'parsing EJSON fields' do
    context 'date' do
      it 'is not parsed when given a bad value' do
        expect(subject.parse '{"a": {"$date" : "something"}}').
          to eq('a' => { '$date' => 'something' })
      end

      it 'parses proper $date EJSON fields' do
        parsed = subject.parse '{"a" : {"$date": 135820576553}}'

        expect(parsed['a']).to eq Time.at(ruby_epoch)
      end

      it 'parses nested EJSON date fields' do
        parsed = subject.parse '{"a" : {"b" : {"$date": 135820576553}}}'

        expect(parsed['a']['b']).to eq Time.at(ruby_epoch)
      end

      it 'parses nested $dates within $escapes' do
        parsed = subject.parse(
          '{"a" : {"$escape": {"$date" : {"date" : {"$date": 135820576553}}}}}'
        )

        expect(parsed['a']['$date']['date']).to eq Time.at(ruby_epoch)
      end

      it 'parses multiple EJSON date fields' do
        ejson = begin
          %({"when":{"$date":#{epoch}},"then":{"$date":#{epoch}}})
        end

        expect(subject.parse ejson).to eq(
          "when" => Time.at(ruby_epoch),
          "then" => Time.at(ruby_epoch)
        )
      end
    end
  end
end

describe Volt::EJSON, '.stringify' do
  subject { Volt::EJSON }
  context 'marshaling dates' do
    let(:now) { Time.now }
    let(:now_js_epoch) { now.to_i * 1_000 }

    it 'does nothing with regular hashes' do
      stringified = subject.stringify plain: 'jane'

      expect(stringified).to eq '{"plain":"jane"}'
    end

    it 'marshals when given a date' do
      stringified = subject.stringify when: now

      expect(stringified).to eq %({"when":{"$date":#{now_js_epoch}}})
    end

    it 'marshals nested dates' do
      stringified = subject.stringify how: { when: now }

      expect(stringified).to eq %({"how":{"when":{"$date":#{now_js_epoch}}}})
    end

    it 'marshals multiple dates' do
      stringified = subject.stringify when: now, then: now

      expect(stringified.gsub(' ', '')).to eq(
        %({"when":{"$date":#{now_js_epoch}},"then":{"$date":#{now_js_epoch}}})
      )
    end

    it 'should convert symbols to strings' do
      stringified = subject.stringify({something: :awesome})

      expect(stringified).to eq('{"something":"awesome"}')
    end

    it 'escapes reserved key when type is incorrect' do
      stringified = subject.stringify '$date' => 'something'

      expect(stringified).to eq '{"$escape":{"$date":"something"}}'
    end
  end
end