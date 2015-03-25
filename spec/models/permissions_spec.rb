require 'spec_helper'


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

class ::TestDenyDelete < Volt::Model
  permissions(:delete) do
    deny
  end
end

class ::TestDenyReadName < Volt::Model
  permissions(:read) do
    deny :name
  end
end

describe "model permissions" do
  it 'should follow CRUD states when checking permissions' do
    todo = TestUserTodoWithCrudStates.new.buffer

    spec_err = nil

    todo._name = 'Test Todo'
    todo.save!.then do
      # Don't allow it to change
      todo._name = 'Jimmy'

      todo.save!.then do
        spec_err = "should not have saved"
      end.fail do |err|
        expect(err).to eq({:name=>["can not be changed"]})
      end
    end.fail do |err|
      spec_err = "Did not save because: #{err.inspect}"
    end

    if spec_err
      fail spec_err
    end
  end

  # it 'should deny an insert/create if a deny without fields' do
  #   store._todos << {name: 'Ryan'}
  # end


  if RUBY_PLATFORM != 'opal'
    describe "read permissions" do
      it 'should deny read on a field' do
        model = store._test_deny_read_names.buffer
        model._name = 'Jimmy'
        model._other = 'should be visible'

        model.save!.sync

        # Clear the identity map, so we can load up a fresh copy
        model.save_to.persistor.clear_identity_map

        reloaded = store._test_deny_read_names.fetch_first.sync

        expect(reloaded._name).to eq(nil)
        expect(reloaded._other).to eq('should be visible')
      end
    end

    it 'should prevent delete if denied' do
      model = store._test_deny_deletes.buffer

      model.save!.then do
        # Saved
        count = 0

        store._test_deny_deletes.delete(model).then do
          # deleted
          count += 1
        end

        expect(count).to eq(1)
      end
    end
  end
end