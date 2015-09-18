require 'spec_helper'

if RUBY_PLATFORM != 'opal'
  describe UserTasks do
    let(:user_promise) { double('UserPromise', then: true) }
    let(:fake_response) { double('FakeResponse', first: user_promise) }

    let(:fake_users_collection) do
      double('FakeUsersCollection', where: fake_response)
    end

    let(:fake_store) { double('FakeStore', _users: fake_users_collection) }

    let(:login_info) { { 'login' => 'Marty', 'password' => 'McFly' } }

    before do
      allow(volt_app).to receive(:store).and_return fake_store
      allow(User).to receive(:login_field).and_return 'user'
      allow(user_promise).to receive(:then).and_yield(user)
    end

    subject { UserTasks.new(Volt.current_app) }

    describe '#login' do
      context 'with no matching user' do
        let(:user) { false }

        it 'raises VoltUserError' do
          expect { subject.login(login_info) }.
            to raise_error('User could not be found')
        end
      end

      context 'with a matching user' do
        let(:password) { BCrypt::Password.create(login_info['password']) }
        let(:user) { double('User', id: 1, _hashed_password: password) }

        it 'fails on bad password' do
          expect { subject.login(login_info.merge 'password' => 'Not McFly') }.
            to raise_error('Password did not match')
        end

        it 'fails with missing app_secret' do
          allow(Volt.config).to receive(:app_secret).and_return false

          expect { subject.login(login_info) }.
            to raise_error('app_secret is not configured')
        end

        it 'generates a signature digest' do
          allow(Digest::SHA256).to receive(:hexdigest).and_call_original

          subject.login(login_info)

          expect(Digest::SHA256).to have_received(:hexdigest).with(
            "#{Volt.config.app_secret}::#{user.id}"
          )
        end
      end
    end
  end
end
