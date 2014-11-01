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

  def test2
    cookies._awesome = 'yes'
  end
end