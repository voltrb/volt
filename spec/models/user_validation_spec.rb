require 'spec_helper'
require 'volt/models'

class TestUserTodo < Volt::Model
  own_by_user
end


describe Volt::UserValidatorHelpers do
  # it 'should assign user_id when owning by a user' do
  #   allow(Volt).to receive(:user_id) { 294 }
  #
  #   todo = TestUserTodo.new
  #   expect(todo._user_id).to eq(nil)
  #   todo.errors
  #
  #   expect(todo._user_id).to eq(294)
  # end
  #
  # it 'should not allow the user_id to be changed' do
  #   allow(Volt).to receive(:user_id) { 294 }
  #
  #   todo = TestUserTodo.new
  #
  #   expect(todo._user_id).to eq(nil)
  #   todo.errors
  #   expect(todo._user_id).to eq(294)
  #
  #   allow(Volt).to receive(:user_id) { 924 }
  #
  #   todo.errors
  #   expect(todo._user_id).to eq(294)
  # end
end