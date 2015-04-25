class Fridge < Volt::Model
  validate :name, unique: true
end
