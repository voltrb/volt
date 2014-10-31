class UsersTestController < Volt::ModelController
  def index
    self.model = store._users.buffer
  end

  def signup
    p = Promise.new.resolve(1)

    e = p.then do
      2
    end.fail do
      puts "fail"
    end

    e.then do |v|
      puts v
    end
    # puts "Signup"
    # model.save! do
    #   puts "Saved"
    # end.fail do |err|
    #   puts "Fail with: #{err.inspect}"
    # end
  end
end