# A Volt::Model class to track of which migrations have been run
class MigrationVersion < Volt::Model
  field :version, Fixnum, nil: false, default: 0

  index :version, unique: true
end
