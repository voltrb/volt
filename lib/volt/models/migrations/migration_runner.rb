# The migration runner runs the migrations and tracks the versions that have
# been run.
require 'volt/models/migrations/migration_version'
require 'volt/models/migrations/migration'

module Volt
  class DuplicateMigrationTimestamp < RuntimeError ; end

  class MigrationRunner
    # The args are passed to the Volt::Migration
    def initialize(*args)
      @args = args
    end

    # Runs all migrations up
    def run(direction=:up, util_version=nil)
      # Get the disk versions
      disk_version_paths = self.disk_versions
      disk_versions = disk_version_paths.map {|v| v[0] }

      # Get the db versions
      ran_versions = self.ran_versions

      if direction == :up
        # Run all that are on disk, but haven't been run (from the db)
        need_to_run_versions = disk_versions - ran_versions

        if util_version
          # remove any versions > the util_version, since the user is saying run
          # "up" migrations until we hit version X
          need_to_run_versions.reject! {|version| version > util_version }
        end
      else
        # Run down on all versions that are in the db.  If the file doesn't exist
        need_to_run_versions = ran_versions

        if util_version
          # remove any versions < the util_version, since the user is saying run
          # "up" migrations until we hit version X
          need_to_run_versions.reject! {|version| version < util_version }
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

    def migration_versions
      Volt.current_app.store.migration_versions
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
        migration_versions.create(version: version)
      else
        # Remove that it ran
        migration_versions.where(version: version).first.sync.destroy
      end
    end
  end
end
