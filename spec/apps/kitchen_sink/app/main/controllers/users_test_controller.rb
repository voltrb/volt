class UsersTestController < Volt::ModelController
  def signup
    UserTasks.create_user('ryanstout@gmail.com', 'temppass').then do |result|
      puts "Result: #{result.inspect}"
    end.fail do |error|
      puts "Error: #{error.inspect}"
    end
  end
end