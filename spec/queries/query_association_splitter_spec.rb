require 'spec_helper'

if RUBY_PLATFORM != 'opal'
  describe Volt::QueryAssociationSplitter do
    it 'should split a query and return the associations' do
      query = [:where, {name: 'Bob'}]
      includes = ['includes', [:posts, [:posts, :comments], :links]]
      new_query, associations = Volt::QueryAssociationSplitter.split([query, includes])

      expect(new_query).to eq([query])
      expect(associations).to eq({:posts=>{:comments=>{}}, :links=>{}})
    end
  end
end
