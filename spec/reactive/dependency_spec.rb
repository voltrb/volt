require 'spec_helper'

describe Volt::Dependency do
  it 'should trigger on_dep and on_stop_dep when setup and torn down' do
    dep_count = 0
    stop_dep_count = 0
    dep = Volt::Dependency.new(-> { dep_count += 1 }, -> { stop_dep_count += 1 })

    expect(dep_count).to eq(0)
    expect(stop_dep_count).to eq(0)

    a = -> { dep.depend }.watch!
    b = -> { dep.depend }.watch!

    expect(dep_count).to eq(1)
    expect(stop_dep_count).to eq(0)

    a.stop
    expect(dep_count).to eq(1)
    expect(stop_dep_count).to eq(0)

    b.stop
    expect(dep_count).to eq(1)
    expect(stop_dep_count).to eq(1)

    # Make sure it triggers if we watch again
    c = -> { dep.depend }.watch!
    d = -> { dep.depend }.watch!

    expect(dep_count).to eq(2)
    expect(stop_dep_count).to eq(1)

    c.stop
    expect(dep_count).to eq(2)
    expect(stop_dep_count).to eq(1)

    d.stop
    expect(dep_count).to eq(2)
    expect(stop_dep_count).to eq(2)
  end

  it 'should trigger on_dep and on_stop_dep when changed and setup again' do
    dep_count = 0
    stop_dep_count = 0
    dep = Volt::Dependency.new(-> { dep_count += 1 }, -> { stop_dep_count += 1 })

    expect(dep_count).to eq(0)
    expect(stop_dep_count).to eq(0)

    a = -> { dep.depend }.watch!
    b = -> { dep.depend }.watch!

    expect(dep_count).to eq(1)
    expect(stop_dep_count).to eq(0)

    dep.changed!
    expect(dep_count).to eq(1)
    expect(stop_dep_count).to eq(1)

    # Make sure it triggers if we watch again
    c = -> { dep.depend }.watch!
    d = -> { dep.depend }.watch!

    expect(dep_count).to eq(2)
    expect(stop_dep_count).to eq(1)

    c.stop
    expect(dep_count).to eq(2)
    expect(stop_dep_count).to eq(1)

    d.stop
    expect(dep_count).to eq(2)
    expect(stop_dep_count).to eq(2)
  end
end
