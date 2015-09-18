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

    it 'should create and run a new TaskArgumentFilterer when its filter method is called' do
      filtered_args = TaskArgumentFilterer.filter([{login: 'jam@jam.com', password: 'some password'}])
      expect(filtered_args).to eq([{login:"jam@jam.com", password:"[FILTERED]"}])
    end

  end
end
