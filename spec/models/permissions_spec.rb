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

class ::TestUpdateReadCheck < Volt::Model
  attr_accessor :create_check, :update_check, :read_check

  permissions(:create) do
    self.create_check = true
    allow
  end

  permissions(:update) do
    self.update_check = true
    allow
  end

  permissions(:read) do
    self.read_check = true
    allow
  end
end

class ::TestPromisePermission < Volt::Model
  attr_reader :called_deny
  permissions(:create) do
    $test_promise = Promise.new
    $test_promise.then do
      @called_deny = true
      deny
    end
  end
end

describe 'model permissions' do
  let(:user_todo) { TestUserTodo.new }

  it 'auto-associates users via own_by_user' do
    expect(user_todo).to respond_to(:user)
  end

  it 'should follow CRUD states when checking permissions' do
    todo = TestUserTodoWithCrudStates.new.buffer

    spec_err = nil

    todo._name = 'Test Todo'
    todo.save!.then do
      # Don't allow it to change
      todo._name = 'Jimmy'

      todo.save!.then do
        spec_err = 'should not have saved'
      end.fail do |err|
        expect(err).to eq(name: ['can not be changed'])
      end
    end.fail do |err|
      spec_err = "Did not save because: #{err.inspect}"
    end

    fail spec_err if spec_err
  end

  # it 'should deny an insert/create if a deny without fields' do
  #   store._todos << {name: 'Ryan'}
  # end

  if RUBY_PLATFORM != 'opal'
    describe 'read permissions' do
      it 'should deny read on a field' do
        model = store._test_deny_read_names!.buffer
        model._name = 'Jimmy'
        model._other = 'should be visible'

        model.save!.sync

        # Clear the identity map, so we can load up a fresh copy
        model.save_to.persistor.clear_identity_map

        reloaded = store._test_deny_read_names.first.sync

        expect(reloaded._name).to eq(nil)
        expect(reloaded._other).to eq('should be visible')
      end
    end

    it 'should prevent delete if denied' do
      model = store._test_deny_deletes!.buffer

      model.save!.then do
        # Saved
        count = 0

        store._test_deny_deletes.delete(model).fail do |err|
          # deleted
          count += 1

          match = !!(err =~ /permissions did not allow delete for /)
          expect(match).to eq(true)
        end.sync

        expect(count).to eq(1)
      end.sync
    end

    it 'should not check the read permissions when updating (so that all fields are present for the permissions check)' do
      model = store._test_update_read_checks!.append(name: 'Ryan').sync

      expect(model.new?).to eq(false)

      expect(model.create_check).to eq(true)
      expect(model.read_check).to eq(nil)

      # Update
      model._name = 'Jimmy'

      expect(model.read_check).to eq(nil)
      expect(model.update_check).to eq(true)
    end

    it 'should not check read permissions on buffer save on server' do
      model = store._test_update_read_checks!.buffer

      model._name = 'Ryan'

      # Create
      model.save!

      # Create happens on the save_to, not the buffer
      expect(model.save_to.create_check).to eq(true)
      expect(model.save_to.read_check).to eq(nil)

      # Update
      model._name = 'Jimmy'
      model.save!

      expect(model.save_to.read_check).to eq(nil)
      expect(model.save_to.update_check).to eq(true)
    end

    it 'should not check read on delete, so all fields are available to the permissions block' do
      model = store._test_update_read_checks!.append(name: 'Ryan').sync

      expect(model.read_check).to eq(nil)

      model.destroy

      expect(model.read_check).to eq(nil)
    end

    it 'should allow permission blocks to return a promise' do
      promise = store._test_promise_permissions.create({})

      expect(promise.resolved?).to eq(false)
      expect(promise.rejected?).to eq(false)
      $test_promise.resolve(nil)

      expect(promise.resolved?).to eq(false)
      expect(promise.rejected?).to eq(true)
      # puts "#{promise.error.inspect}"
      # puts promise.error.backtrace.join("\n")
      expect(promise.error.to_s).to match(/permissions did not allow create for/)
    end
  end
end
