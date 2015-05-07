require 'spec_helper'

if RUBY_PLATFORM != 'opal'
  describe TaskArgumentFilterer do
    it 'should filter arguments' do
      filtered_args = TaskArgumentFilterer.new(login: 'jim@jim.com', password: 'some password no one should see').run

      expect(filtered_args).to eq(login: 'jim@jim.com', password: '[FILTERED]')
    end

    it 'should filter in nested args' do
      filtered_args = TaskArgumentFilterer.new([:login, { login: 'jim@jim.com', password: 'some password' }]).run

      expect(filtered_args).to eq([:login, { login: 'jim@jim.com', password: '[FILTERED]' }])
    end
  end
end
