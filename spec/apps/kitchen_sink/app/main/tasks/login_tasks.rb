class LoginTasks < Volt::Task
  def login_first_user
    store.users.first.then do |first_user|
      login_as(first_user)
    end
  end
end