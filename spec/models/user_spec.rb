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
    let!(:user) { Volt::User.new }

    subject { user.password = 'test' }

    if RUBY_PLATFORM != 'opal'
      describe 'when it is a Volt server' do
        before do
          allow(BCrypt::Password).to receive(:create).with('test')
            .and_return 'hashed-password'
        end

        it 'encrypts password' do
          subject

          expect(BCrypt::Password).to have_received :create
        end

        it 'sets _hashed_password to passed value' do
          subject

          expect(user._hashed_password).to eq 'hashed-password'
        end
      end

      it 'should allow updates without validating the password' do
        bob = store._users.buffer(name: 'Bob', email: 'bob@bob.com', password: '39sdjkdf932jklsd')
        bob.save!

        expect(bob._password).to eq(nil)

        bob_buf = bob.buffer

        bob_buf._name = 'Jimmy'

        saved = false
        bob_buf.save! do
          saved = true
        end

        expect(saved).to eq(true)
      end
    end



    describe 'when it is not a Volt server' do
      before do
        allow(Volt).to receive(:server?).and_return false
      end

      subject { user.password = 'a valid test password' }

      it 'sets _password to passed value' do
        subject

        expect(user._password).to eq('a valid test password')
      end
    end
  end
end
