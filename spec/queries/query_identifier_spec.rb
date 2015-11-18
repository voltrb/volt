require 'spec_helper'

describe Volt::QueryIdentifier do
  let(:ident) { subject }
  it 'should call first on ident' do
    expect(ident.name.to_query).to eq(["c", "ident", "name"])
  end

  it 'should group according to method calls' do
    expect((ident.name < 5).to_query).to eq(["c", ["c", "ident", "name"], "<", 5])
  end

  it 'should group & into a Volt::QueryOp' do
    query = ((ident.lat > 80) & (ident.lng < 50))
    expect(query.to_query).to eq(
      [
        "c",
        ["c", ["c", "ident", "lat"], ">", 80],
        "&",
        ["c", ["c", "ident", "lng"], "<", 50]
      ]
    )
  end

  it 'should place the . correctly when coercing' do
    query = (5 < ident.lat)
    expect(query.to_query).to eq(["c", 5, "<", ["c", "ident", "lat"]])
  end

  it 'should group | into a Volt::QueryOp' do
    query = ((ident.lat > 80) & (ident.lng < 50)) | (ident.name == 'Bob')
    expect(query.to_query).to eq(
      [
        "c",
        [
          "c",
          ["c", ["c", "ident", "lat"], ">", 80],
          '&',
          ["c",
           ["c", "ident", "lng"], "<", 50]
        ],
        '|',
        ["c", ["c", "ident", "name"], "==", "Bob"]
      ]
    )
  end

  it 'should handle negation with ~' do
    query = ((ident.name == 'Ryan') & ~(ident.lat > 40))
    expect(query.to_query).to eq(
      [
        "c",
        ["c", ["c", "ident", "name"], "==", "Ryan"],
        "&",
        ["c",
         ["c", ["c", "ident", "lat"], ">", 40],
         "~"
         ]
      ]
    )
  end

  it 'should handle arrays as call arguments' do
    query = (ident.name == [1,2,3])
    expect(query.to_query).to eq(["c", ["c", "ident", "name"], "==", ["a", 1, 2, 3]])
  end

  it 'should handle =~' do
    query = (ident.name =~ 'Bob')
    expect(query.to_query).to eq(["c", ["c", "ident", "name"], "=~", "Bob"])
  end

  # This code fails until the following is fixed:
  # https://github.com/opal/opal/issues/1138
  # it 'should handle !~' do
  #   query = (ident.name !~ 'Bob')
  #   expect(query.to_query).to eq(["c", ["c", "ident", "name"], "!~", "Bob"])
  # end

  it 'should handle addition and comparison' do
    query = (ident.pounds + 10 < 20)
    expect(query.to_query).to eq(
      [
        "c",
        [
          "c",
          ["c", "ident", "pounds"],
          "+",
          10
        ],
        "<",
        20
      ]
    )
  end

  it 'should handle regex comparisons' do
    query = (ident.message =~ /something/)
    expect(query.to_query).to eq(
      [
        "c",
        ["c", "ident", "message"],
        "=~",
        ["r", /something/.to_s]
      ]
    )
  end

  it 'should handle method calls like max'
end
