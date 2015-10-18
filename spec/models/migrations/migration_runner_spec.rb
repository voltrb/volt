require 'spec_helper'
require 'volt/models/migrations/migration_runner'

describe Volt::MigrationRunner do
  let(:migration_app_path) { File.expand_path("#{File.dirname(__FILE__)}/../../apps/migrations") }
  let(:migration_folder) { File.expand_path("#{migration_app_path}/config/db/migrations") }
  let(:runner) { Volt::MigrationRunner.new }
  it 'should run migrations that have not been run yet' do
    first = store.migration_versions.where(version: 1445111704).first.sync
    expect(!!first).to eq(false)

    runner.run_migration("#{migration_folder}/1445111704_migration1.rb", :up)

    first = store.migration_versions.where(version: 1445111704).first.sync
    expect(!!first).to eq(true)
  end

  it 'should migrate up and down' do
    count = store.migration_versions.count.sync
    expect(count).to eq(0)

    expect(Volt).to receive(:root).and_return(migration_app_path).at_least(:once)

    runner.run(:up)

    count = store.migration_versions.count.sync
    expect(count).to eq(3)

    runner.run(:down)

    count = store.migration_versions.count.sync
    expect(count).to eq(0)
  end

  it 'should migrate up until a number' do
    count = store.migration_versions.count.sync
    expect(count).to eq(0)

    expect(Volt).to receive(:root).and_return(migration_app_path).at_least(:once)

    runner.run(:up, 1445113517)

    count = store.migration_versions.count.sync
    expect(count).to eq(2)
  end

  it 'should migrate down to a version number' do
    count = store.migration_versions.count.sync
    expect(count).to eq(0)

    expect(Volt).to receive(:root).and_return(migration_app_path).at_least(:once)

    runner.run(:up)

    count = store.migration_versions.count.sync
    expect(count).to eq(3)

    runner.run(:down, 1445113517)

    count = store.migration_versions.count.sync
    expect(count).to eq(1)
  end
end
