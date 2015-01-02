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

  # Currently Class#class_variable_set/get isn't in opal
  # https://github.com/opal/opal/issues/677
  unless RUBY_PLATFORM == 'opal'
    describe '#invalidate!' do

    let(:computation) { Volt::Computation.new ->{} }

    before(:each) do
      Volt::Computation.class_variable_set :@@flush_queue, []
    end

    context 'when stopped' do
      before(:each) { computation.instance_variable_set :@stopped, true }

      it "doesn't add self to flush queue" do
        computation.invalidate!

        expect(Volt::Computation.class_variable_get :@@flush_queue).to be_empty
      end
    end

    context 'when computing' do
      before(:each) { computation.instance_variable_set :@computing, true }

      it "doesn't add self to flush queue" do
        computation.invalidate!

        expect(Volt::Computation.class_variable_get :@@flush_queue).to be_empty
      end
    end

    context 'when not stopped and not computing' do
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
