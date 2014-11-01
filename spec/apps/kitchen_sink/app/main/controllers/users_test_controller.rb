class UsersTestController < Volt::ModelController
  def index
    self.model = store._users.buffer
  end

  def signup
    model.save!.then do |a|
      puts "Saved"
    end.fail do |err|
      puts "Fail with: #{err.inspect}"
    end
  end

  def login
    UserTasks.login('ryanstout@gmail.com', 'temppass').then do |result|
      puts "RESULT: #{result}"

      cookies._user_id = result
    end.fail do |err|
      puts "ERR: #{err.inspect}"
    end
  end
end