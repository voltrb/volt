require 'spec_helper'

if RUBY_PLATFORM != 'opal'
  describe Volt::QueryDiff do
    it 'should return a diff for moving records' do
      a = [
        {id: 1, name: 'Bob'},
        {id: 2, name: 'Jim'},
        {id: 3, name: 'Rob'}
      ]
      b = [
        {id: 3, name: 'Rob'},
        {id: 1, name: 'Bob'},
        {id: 2, name: 'Jim'}
      ]

      diff = Volt::QueryDiff.new(a).run(b)

      expect(diff).to eq([["m", 3, 0]])
    end

    it 'should return a diff moved records 2' do
      a = [
        {id: 1, name: 'Bob'},
        {id: 2, name: 'Jim'},
        {id: 3, name: 'Rob'},
        {id: 4, name: 'Meg'}
      ]
      b = [
        {id: 3, name: 'Rob'},
        {id: 1, name: 'Bob'},
        {id: 4, name: 'Meg'},
        {id: 2, name: 'Jim'}
      ]

      diff = Volt::QueryDiff.new(a).run(b)

      expect(diff).to eq([
                           ["m", 3, 0],
                           ["m", 4, 2]
      ])
    end

    it 'should return a diff with removed records' do
      a = [
        {id: 1, name: 'Bob'},
        {id: 2, name: 'Jim'},
        {id: 3, name: 'Rob'}
      ]
      b = [
        {id: 3, name: 'Rob'},
        {id: 2, name: 'Jim'}
      ]

      diff = Volt::QueryDiff.new(a).run(b)

      expect(diff).to eq([
                           ["r", 1],
                           ["m", 3, 0]
      ])
    end

    it 'should return a diff for updated records' do
      a = [
        {id: 1, name: 'Bob'},
        {id: 2, name: 'Jim'},
        {id: 3, name: 'Rob'}
      ]
      b = [
        {id: 2, name: 'Jim', admin: true},
        {id: 1, name: 'Bobby'},
        {id: 3, name: 'Rob'}
      ]

      diff = Volt::QueryDiff.new(a).run(b)

      expect(diff).to eq(
        [
          ["m", 2, 0],
          ["c", 1, {:id=>1, :name=>"Bobby"}],
          ["c", 2, {:id=>2, :name=>"Jim", :admin=>true}]
        ]
      )
    end

    it 'should handle nested updates' do
      a = [
        {id: 1, name: 'Bob'},
        {id: 2, name: 'Jim'},
        {id: 3, name: 'Rob'}
      ]
      b = [
        {id: 2, name: 'Jim', admin: true},
        {id: 1, name: 'Bobby'},
        {id: 3, name: 'Rob'}
      ]

      diff = Volt::QueryDiff.new(a).run(b)

      expect(diff).to eq(
        [
          ["m", 2, 0],
          ["c", 1, {:id=>1, :name=>"Bobby"}],
          ["c", 2, {:id=>2, :name=>"Jim", :admin=>true}]
        ]
      )
    end

    it 'should handle complex transforms' do
      a = [
        {id: 1, name: 'Bob'},
        {id: 2, name: 'Jim'},
        {id: 3, name: 'Rob'}
      ]
      b = [
        {id: 2, name: 'Jim', admin: true},
        {id: 1, name: 'Bobby'},
        {id: 3, name: 'Rob'}
      ]

      diff = Volt::QueryDiff.new(a).run(b)

      expect(diff).to eq(
        [
          ["m", 2, 0],
          ["c", 1, {:id=>1, :name=>"Bobby"}],
          ["c", 2, {:id=>2, :name=>"Jim", :admin=>true}]
        ]
      )
    end
  end
end
