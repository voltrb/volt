class UsersTestController < Volt::ModelController
  def index
    self.model = store._users.buffer
  end

  def signup
    puts "Signup"
    model.save!.then do |a|
      puts "Saved"
    end.fail do |err|
      puts "Fail with: #{err.inspect}"
    end
  end

  def login
    puts "USER LOGIN"
    Volt.login(page._login._email, page._login._password).then do |result|
      puts "Login Success"
    end.fail do |err|
      puts "ERR: #{err.inspect}"
    end
  end

  def logout
    User.logout
  end
end