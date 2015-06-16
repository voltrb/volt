class User < Volt::User
  # login_field is set to :email by default and can be changed to :username
  # in config/app.rb
  field login_field
  field :name

  validate login_field, unique: true, length: 8
  validate :email, email: true
end
