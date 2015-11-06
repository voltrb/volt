# The migration runner runs the migrations and tracks the versions that have
# been run.
require 'volt/models/migrations/migration'

module Volt
  class DuplicateMigrationTimestamp < RuntimeError ; end

  class MigrationRunner
    # The args are passed to each Volt::Migration, (typically just the @db)
    def initialize(*args)
      @args = args
      ensure_migration_versions_table
    end

    # Runs all migrations up
    def run(direction=:up, until_version=nil)
      # Get the disk versions
      disk_version_paths = self.disk_versions
      disk_versions = disk_version_paths.map {|v| v[0] }

      # Get the db versions
      ran_versions = self.all_versions

      if direction == :up
        # Run all that are on disk, but haven't been run (from the db)
        need_to_run_versions = disk_versions - ran_versions

        if until_version
          # remove any versions > the until_version, since the user is saying run
          # "up" migrations until we hit version X
          need_to_run_versions.reject! {|version| version > until_version }
        end
      else
        # Run down on all versions that are in the db.  If the file doesn't exist
        need_to_run_versions = ran_versions

        if until_version
          # remove any versions < the until_version, since the user is saying run
          # "up" migrations until we hit version X
          need_to_run_versions.reject! {|version| version < until_version }
        end
      end

      need_to_run_versions.each do |version|
        path = disk_version_paths[version]

        unless path
          raise "The database has a migration version of #{version}, but no matching migration file could be found for the down migration"
        end

        run_migration(path, direction)
      end
    end

    # Grab the version numbers and files for each migration on disk.  Raises an
    # exception if two migrations have the same number
    def disk_versions
      versions = {}
      Dir["#{Volt.root}/config/db/migrations/*.rb"].map do |path|
        version = version_for_path(path)

        if (path2 = versions[version])
          raise DuplicateMigrationTimestamp, "Two migrations have the same version number: #{path} and #{path2}"
        end

        versions[version] = path
      end

      versions
    end

    def version_for_path(path)
      File.basename(path)[/^[0-9]+/].to_i
    end

    # Get the number for all versions that have been run
    def ran_versions
      migration_versions.all.sync.map {|v| v.version }
    end

    def run_migration(path, direction=:up)
      Volt.logger.info("Run #{direction} migration #{File.basename(path)}")
      version = version_for_path(path)

      # When we require, we use the inherited callback to figure out what class
      # was loaded.
      migration_klass = nil
      listener = Volt::Migration.on('inherited') do |klass|
        migration_klass = klass
      end

      require(path)

      # Remove the inherited listener
      listener.remove

      unless migration_klass
        raise "No class inheriting from Volt::Migration was defined in #{path}"
      end

      unless [:up, :down].include?(direction)
        raise "Only up and down migrations are supported"
      end

      # Run the up migration
      migration_klass.new(*@args).send(direction)

      # Remove the object
      Object.send(:remove_const, migration_klass.name.to_sym)

      # Remove the require
      $LOADED_FEATURES.reject! {|p| p == path }

      if direction == :up
        # Track that it ran
        add_version(version)
      else
        # Remove that it ran
        remove_version(version)
      end
    end

    # Implement the following in your data provider to allow migrations.  We
    # can't use Volt::Model until after the reconcile step has happened, so
    # these methods need to work directly with the database.
    def ensure_migration_versions_table
      raise "not implemented"
    end

    def add_version(version)
      raise "not implemented"
    end

    def has_version?(version)
      raise "not implemented"
    end

    def remove_version(version)
      raise "not implemented"
    end

    def all_versions
      raise "not implemented"
    end
  end
end
