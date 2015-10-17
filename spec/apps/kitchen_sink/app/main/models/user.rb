class User < Volt::User
  # login_field is set to :email by default and can be changed to :username
  # in config/app.rb
  field login_field
  field :name

  validate login_field, unique: true, length: 8
  validate :email, email: true

  unless RUBY_PLATFORM == "opal"
    Volt.current_app.on("user_connect") do |user_id|
      begin
        Volt.current_app.store.users.where(id: user_id).first.sync._event_triggered = "user_connect"
      rescue
        #we rescue as this callback will also get called from the SocketConnectionHandler specs (and will fail)
      end
    end

    Volt.current_app.on("user_disconnect") do |user_id|
      begin
        user = Volt.current_app.store.users.where(id: user_id).first.sync._event_triggered = "user_disconnect"
      rescue => e
        #we rescue as this callback will also get called from the SocketConnectionHandler specs (and will fail)
      end
    end
  end
end
