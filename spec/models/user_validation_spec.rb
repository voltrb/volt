require 'spec_helper'
require 'volt/models'

class TestUserTodo < Volt::Model
  own_by_user

  permissions(:update) do
    deny :user_id
  end
end

describe Volt::UserValidatorHelpers do
  before do
    allow(Volt).to receive(:user_id) { 294 }
  end

  it 'should assign user_id when owning by a user' do
    todo = TestUserTodo.new
    expect(todo._user_id).to eq(294)
  end

  # it 'should not allow the user_id to be changed' do
  #   todo = TestUserTodo.new
  #
  #   expect(todo.new?).to eq(true)
  #   expect(todo._user_id).to eq(nil)
  #
  #   todo._name = 'Ryan'
  #
  #   expect(todo._user_id).to eq(294)
  #   expect(todo.new?).to eq(false)
  # end
end