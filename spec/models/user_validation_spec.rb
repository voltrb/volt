require 'spec_helper'

class TestUserTodo < Volt::Model
  own_by_user

  permissions(:update) do
    deny :user_id
  end
end

describe Volt::UserValidatorHelpers do
  context 'with user' do
    before do
      allow(Volt).to receive(:current_user_id) { 294 }
    end

    it 'should assign user_id when owning by a user' do
      todo = TestUserTodo.new
      expect(todo._user_id).to eq(294)
    end

    it 'should not allow the user_id to be changed' do
      todo = TestUserTodo.new
      expect(todo._user_id).to eq(294)

      todo._user_id = 500

      expect(todo._user_id).to eq(294)
    end
  end
end
