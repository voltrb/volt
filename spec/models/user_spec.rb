require 'spec_helper'
require 'volt/models/user'

class FakeConfig
  def public; self; end
  def auth; self; end
  def use_username; true; end
end

describe Volt::User do
  describe '.login_field' do
    subject { Volt::User.login_field }

    context 'when use_username is set to true' do
      before do
        allow(Volt).to receive(:config).and_return FakeConfig.new
      end

      it "returns :username" do
        expect(subject).to eq :username
      end
    end

    context 'when use_username is not set' do
      it "returns :email" do
        expect(subject).to eq :email
      end
    end
  end

  describe '#password=' do
    let!(:user) { Volt::User.new }

    subject { user.password = 'test' }

    if RUBY_PLATFORM != 'opal'
      context 'when it is a Volt server' do
        before do
          allow(BCrypt::Password).to receive(:create).with('test').
            and_return 'hashed-password'
        end

        it "encrypts password" do
          subject

          expect(BCrypt::Password).to have_received :create
        end

        it 'sets _hashed_password to passed value' do
          subject

          expect(user._hashed_password).to eq "hashed-password"
        end
      end
    end

    context 'when it is not a Volt server' do
      before do
        allow(Volt).to receive(:server?).and_return false
      end

      it 'sets _password to passed value' do
        subject

        expect(user._password).to eq 'test'
      end
    end
  end
end
