require 'spec_helper'
require 'volt/utils/data_transformer'

describe Volt::DataTransformer do
  it 'should transform values' do
    data = {
      name: 'Bob',
      stuff: [
        {key: /regex/}
      ],
      other: /another regex/,
      /some reg/ => 'value'
    }

    transformed = {
      :name=>"Bob",
      :stuff=>[
        {:key=>"a regex"}
      ],
      :other=>"a regex",
      "a regex"=>"value"
    }

    result = Volt::DataTransformer.transform(data) do |value|
      if value.is_a?(Regexp)
        'a regex'
      else
        value
      end
    end

    expect(result).to eq(transformed)
  end

  it 'should transform keys' do
    data = {
      'name' => 'Ryan',
      'info' => [
        {'place' => 'Bozeman'}
      ]
    }
    transformed = {:name=>"Ryan", :info=>[{:place=>"Bozeman"}]}
    result = Volt::DataTransformer.transform_keys(data) do |key|
      key.to_sym
    end

    expect(result).to eq(transformed)
  end
end
