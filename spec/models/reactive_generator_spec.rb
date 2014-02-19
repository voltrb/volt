require 'volt/models'

describe ReactiveGenerator do
  before do
    @object = {
      name: ReactiveValue.new('bob'),
      location: {
        town: ReactiveValue.new('Bozeman'),
        places: [
          ReactiveValue.new('The Garage'),
          ReactiveValue.new('Ale Works')
        ]
      }
    }
  end

  it "should find all reactive values in any object" do
    values = ReactiveGenerator.find_reactives(@object)

    expect(values.map(&:cur)).to eq(['bob', 'Bozeman', 'The Garage', 'Ale Works'])
  end

  it "should return a reactive value that changes whenever a child reactive value changes" do
    values = ReactiveGenerator.from_hash(@object)

    count = 0
    values.on('changed') { count += 1 }
    expect(count).to eq(0)

    @object[:name].cur = 'jim'

    expect(count).to eq(1)

    @object[:location][:places].last.cur = 'Starkies'
    expect(count).to eq(2)

    expect(values.to_h).to eq({
      name: 'jim',
      location: {
        town: 'Bozeman',
        places: [
          'The Garage',
          'Starkies'
        ]
      }
    })
  end

  it "should optionally return a normal hash if there are no child reactive values" do
    values = ReactiveGenerator.from_hash({name: 'bob'})
    expect(values.reactive?).to eq(true)
    expect(values.is_a?(Hash)).to eq(false)

    values = ReactiveGenerator.from_hash({name: 'bob'}, true)
    expect(values.reactive?).to eq(false)
    expect(values.is_a?(Hash)).to eq(true)
  end
end
