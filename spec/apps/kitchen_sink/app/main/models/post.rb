class Post < Volt::Model
  field :title, String

  validate :title, length: 5

end
