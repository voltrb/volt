module Volt
  module CliSubclasses
    class Migrate < Thor
      desc 'migrate up', 'migrate up'
      method_option :version, type: :string, banner: 'Migrate up to the specified VERSION'
      def up(version=nil)
        Volt.boot(Dir.pwd)
        require 'volt/models/migrations/migration_runner'

        Volt::MigrationRunner.new.run(:up, version)
      end

      desc 'migrate down', 'migrate down'
      method_option :version, type: :string, banner: 'Migrate down to the specified VERSION'
      def down(version=nil)
        Volt.boot(Dir.pwd)
        require 'volt/models/migrations/migration_runner'

        Volt::MigrationRunner.new.run(:down, version)
      end

      default_task :up

    end
  end
end
