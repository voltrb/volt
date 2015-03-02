require 'spec_helper'

describe Volt::Computation do
  it 'should trigger again when a dependent changes' do
    a = Volt::ReactiveHash.new

    values = []

    -> { values << a[0] }.watch!

    expect(values).to eq([nil])

    a[0] = 'one'
    Volt::Computation.flush!
    expect(values).to eq([nil, 'one'])

    a[0] = 'two'
    Volt::Computation.flush!
    expect(values).to eq([nil, 'one', 'two'])
  end

  it 'should not trigger after the computation is stopped' do
    a = Volt::ReactiveHash.new

    values = []
    computation = -> { values << a[0] }.watch!

    expect(values).to eq([nil])

    a[0] = 'one'
    Volt::Computation.flush!
    expect(values).to eq([nil, 'one'])

    computation.stop

    a[0] = 'two'
    Volt::Computation.flush!
    expect(values).to eq([nil, 'one'])
  end

  it 'should watch_until! a value matches' do
    a = Volt::ReactiveHash.new

    a[:b] = 5

    count = 0
    -> do
      a[:b]
    end.watch_until!(10) do
      count += 1
    end

    expect(count).to eq(0)

    a[:b] = 7
    Volt::Computation.flush!
    expect(count).to eq(0)

    a[:b] = 10
    Volt::Computation.flush!
    expect(count).to eq(1)

    # Should only trigger once
    a[:b] = 5
    Volt::Computation.flush!
    expect(count).to eq(1)

    a[:b] = 10
    Volt::Computation.flush!
    expect(count).to eq(1)
  end

  it 'should trigger a changed dependency only once on a flush' do
    a = Volt::Dependency.new

    count = 0
    -> { count += 1 ; a.depend }.watch!

    expect(count).to eq(1)

    a.changed!
    a.changed!
    a.changed!

    expect(count).to eq(1)

    Volt::Computation.flush!

    expect(count).to eq(2)
  end

  it 'should support nested watches' do
    a = Volt::ReactiveHash.new

    values = []
    -> do
      values << a[0]

      -> do
        values << a[1]
      end.watch!
    end.watch!

    expect(values).to eq([nil, nil])

    a[1] = 'inner'
    Volt::Computation.flush!
    expect(values).to eq([nil, nil, 'inner'])

    a[0] = 'outer'
    Volt::Computation.flush!
    expect(values).to eq([nil, nil, 'inner', 'outer', 'inner'])
  end

  describe "watch_and_resolve!" do
    it 'should resolve any returnted promises' do
      promise = Promise.new.resolve('resolved')
      count = 0

      -> { promise }.watch_and_resolve! do |result|
        expect(result).to eq('resolved')
        count += 1
      end

      expect(count).to eq(1)
    end
  end

  # Currently Class#class_variable_set/get isn't in opal
  # https://github.com/opal/opal/issues/677
  unless RUBY_PLATFORM == 'opal'
    describe '#invalidate!' do

    let(:computation) { Volt::Computation.new ->{} }

    before(:each) do
      Volt::Computation.class_variable_set :@@flush_queue, []
    end

    describe 'when stopped' do
      before(:each) { computation.instance_variable_set :@stopped, true }

      it "doesn't add self to flush queue" do
        computation.invalidate!

        expect(Volt::Computation.class_variable_get :@@flush_queue).to be_empty
      end
    end

    describe 'when computing' do
      before(:each) { computation.instance_variable_set :@computing, true }

      it "doesn't add self to flush queue" do
        computation.invalidate!

        expect(Volt::Computation.class_variable_get :@@flush_queue).to be_empty
      end
    end

    describe 'when not stopped and not computing' do
      before(:each) do
        computation.instance_variable_set :@stopped,   false
        computation.instance_variable_set :@computing, false
      end

      it 'adds self to flush queue' do
        computation.invalidate!

        expect(Volt::Computation.class_variable_get :@@flush_queue).to match_array([computation])
      end
    end
  end
  end
end
