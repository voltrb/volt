require 'spec_helper'
require 'volt/models/user'

class FakeConfig
  def public
    self
  end

  def auth
    self
  end

  def use_username
    true
  end
end

describe Volt::User do
  describe '.login_field' do
    subject { Volt::User.login_field }

    describe 'when use_username is set to true' do
      before do
        allow(Volt).to receive(:config).and_return FakeConfig.new
      end

      it 'returns :username' do
        expect(subject).to eq :username
      end
    end

    describe 'when use_username is not set' do
      it 'returns :email' do
        expect(subject).to eq :email
      end
    end
  end

  describe '#password=' do
    subject { Volt::User.new(password: 'test') }

    if RUBY_PLATFORM != 'opal'
      describe 'when it is a Volt server' do
        before do
          allow(BCrypt::Password).to receive(:create).with('test')
            .and_return 'hashed-password'
        end

        it 'encrypts password' do
          the_page._users << subject

          expect(BCrypt::Password).to have_received :create
        end

        it 'sets _hashed_password to passed value' do
          the_page._users << subject

          expect(subject.get('hashed_password')).to eq 'hashed-password'
        end
      end

      it 'should allow updates without validating the password' do
        bob = store._users.buffer(name: 'Bob', email: 'bob@bob.com', password: '39sdjkdf932jklsd')
        bob.save!.sync

        Volt.as_user(bob) do

          expect(bob.password).to eq(nil)

          bob_buf = bob.buffer

          bob_buf.name = 'Jimmy'

          saved = false
          bob_buf.save! do
            saved = true
          end

          expect(saved).to eq(true)
        end
      end
    end



    describe 'when it is not a Volt server' do
      before do
        allow(Volt).to receive(:server?).and_return false
      end

      subject { Volt::User.new(password: 'a valid test password') }

      it 'sets password to passed value' do
        expect(subject.password).to eq('a valid test password')
      end
    end
  end
end
