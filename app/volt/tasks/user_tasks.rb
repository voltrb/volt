class UserTasks < Volt::TaskHandler
  # Login a user, takes a username and password
  def create_user(username, password)
    puts "Add User: #{username} -- #{password.inspect}"
    store._users << { email: username, password: password }
  end
end
