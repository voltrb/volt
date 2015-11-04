unless RUBY_PLATFORM == 'opal'
  require 'spec_helper'
  require 'volt/models/migrations/migration_runner'

  describe Volt::MigrationRunner do
    let(:migration_app_path) { File.expand_path("#{File.dirname(__FILE__)}/../../apps/migrations") }
    let(:migration_folder) { File.expand_path("#{migration_app_path}/config/db/migrations") }
    let(:runner) { Volt::MigrationRunner.new }
    after do
    	# Migration runner changes the db, but doesn't touch store, so cleanup
    	# manually after.
      cleanup_db
    end

    it 'should run migrations that have not been run yet' do
      expect(runner.has_version?(1445111704)).to eq(false)

      runner.run_migration("#{migration_folder}/1445111704_migration1.rb", :up)

      expect(runner.has_version?(1445111704)).to eq(true)
    end

    it 'should migrate up and down' do
      count = runner.all_versions.size
      expect(count).to eq(0)

      expect(Volt).to receive(:root).and_return(migration_app_path).at_least(:once)

      runner.run(:up)

      count = runner.all_versions.size
      expect(count).to eq(3)

      runner.run(:down)

      count = runner.all_versions.size
      expect(count).to eq(0)
    end

    it 'should migrate up until a number' do
      count = runner.all_versions.size
      expect(count).to eq(0)

      expect(Volt).to receive(:root).and_return(migration_app_path).at_least(:once)

      runner.run(:up, 1445113517)

      count = runner.all_versions.size
      expect(count).to eq(2)
    end

    it 'should migrate down to a version number' do
      count = runner.all_versions.size
      expect(count).to eq(0)

      expect(Volt).to receive(:root).and_return(migration_app_path).at_least(:once)

      runner.run(:up)

      count = runner.all_versions.size
      expect(count).to eq(3)

      runner.run(:down, 1445113517)

      count = runner.all_versions.size
      expect(count).to eq(1)
    end
  end
end
