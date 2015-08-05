require 'spec_helper'

class ::QPost < Volt::Model
  has_many :q_comments
end

class ::QComment < Volt::Model
  belongs_to :q_post
end

describe Volt::QueryRunner do
  it 'should run queries' do
    data_store = double('data store')

    query = [[:where, {user_id: 5}]]

    result = [{id: 1, user_id: 5, title: 'Some post'}]
    expect(data_store).to receive(:query).with('q_posts', query).and_return(result)

    query_runner = Volt::QueryRunner.new(data_store, 'q_posts', query)

    expect(query_runner.run).to eq(result)
  end

  it 'should run sub queries' do
    data_store = double('data store')

    query = [[:where, {user_id: 5}], [:includes, :q_comments]]

    result1 = [
      {id: 1, user_id: 5, title: 'Some post'},
      {id: 2, user_id: 5, title: 'Another Post'}
    ]
    expect(data_store).to receive(:query).with(:q_posts, [[:where, {user_id: 5}]])
      .and_return(result1)

    query2 = [[:where, {:q_post_id=>[1, 2]}]]

    result2 = [
      {id: 4, q_post_id: 1, body: 'Some comment'},
      {id: 5, q_post_id: 1, body: 'Another comment'},
      {id: 6, q_post_id: 2, body: 'The best comment'}
    ]
    expect(data_store).to receive(:query).with(:q_comments, query2)
      .and_return(result2)

    query_runner = Volt::QueryRunner.new(data_store, :q_posts, query)

    result3 = [
      {id: 1, user_id: 5, title: 'Some post', q_comments: [
        {id: 4, q_post_id: 1, body: 'Some comment'},
        {id: 5, q_post_id: 1, body: 'Another comment'}
      ]},
      {id: 2, user_id: 5, title: 'Another Post', q_comments: [
        {id: 6, q_post_id: 2, body: 'The best comment'}
      ]}
    ]

    expect(query_runner.run).to eq(result3)
  end
end