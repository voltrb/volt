require 'spec_helper'

describe Volt::Persistors::ArrayStore do
  it 'should make a Cursor using :where_with_block when passing a block to where' do
    cursor = store._users.where({name: 'Bob'}) {|v| v.location == 'Bozeman' }

    expect(cursor.options[:query]).to eq(
      [
        [
          "where_with_block",
          {:name=>"Bob"},
        ["c", ["c", "ident", "location"], "==", "Bozeman"]]
      ]
    )
  end
end
