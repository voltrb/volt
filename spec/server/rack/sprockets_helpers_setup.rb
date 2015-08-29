require 'spec_helper'

describe "sprockets helpers" do
  it 'should expand paths' do
    result = Volt::SprocketsHelpersSetup.expand('/something/cool/../awesome/beans/../../five/six/seven')

    expect(result).to eq('/something/five/six/seven')
  end

  it 'should expand paths2' do
    result = Volt::SprocketsHelpersSetup.expand('bootstrap/assets/css/../fonts/glyphicons-halflings-regular.svg')

    expect(result).to eq('bootstrap/assets/fonts/glyphicons-halflings-regular.svg')
  end
end