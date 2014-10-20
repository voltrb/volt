class UserTasks < Volt::TaskHandler
  # Login a user, takes a username and password
  def create_user(username, password)
    $page.store._users << { email: username, password: password }
  end
end
