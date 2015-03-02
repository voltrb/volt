require 'spec_helper'
require 'volt/models'

class TestUserTodo < Volt::Model
  own_by_user

  permissions(:update) do
    deny :user_id
  end
end

class TestUserTodoWithCrudStates < Volt::Model
  permissions(:create, :update) do |state|
    # Name is set on create, then can not be changed
    deny unless state == :create
  end
end

class TestDenyDelete < Volt::Model
  permissions(:delete) do
    puts "CHECK DELETE---1"
    deny
  end
end

describe Volt::UserValidatorHelpers do
  context "with user" do
    before do
      allow(Volt).to receive(:user_id) { 294 }
    end

    # it 'should assign user_id when owning by a user' do
    #   todo = TestUserTodo.new
    #   expect(todo._user_id).to eq(294)
    # end
    #
    # it 'should not allow the user_id to be changed' do
    #   todo = TestUserTodo.new
    #   expect(todo._user_id).to eq(294)
    #
    #   todo._user_id = 500
    #
    #   expect(todo._user_id).to eq(294)
    # end

    # it 'should follow CRUD states when checking permissions' do
    #   todo = TestUserTodoWithCrudStates.new.buffer
    #
    #   spec_err = nil
    #
    #   todo._name = 'Test Todo'
    #   todo.save!.then do
    #     # Don't allow it to change
    #     todo._name = 'Jimmy'
    #
    #     todo.save!.then do
    #       spec_err = "should not have saved"
    #     end.fail do |err|
    #       expect(err).to eq({:name=>["can not be changed"]})
    #     end
    #   end.fail do |err|
    #     spec_err = "Did not save because: #{err.inspect}"
    #   end
    #
    #   if spec_err
    #     fail spec_err
    #   end
    # end

    it 'should prevent delete if denied' do
      model = $page.store._test_deny_deletes.buffer

      model.save!.then do
        # Saved

        $page.store._test_deny_deletes.delete(model).then do
          # deleted
          puts "DELETED"
        end.fail do |err|
          puts "Delete Fail"
        end
      end.fail do |err|
        puts "ERR: #{err.inspect}"
        puts err.backtrace
      end
    end
  end
end