if RUBY_PLATFORM != 'opal'
  describe 'Volt::QueryTasks' do
    before do
      load File.join(File.dirname(__FILE__), '../../app/volt/tasks/query_tasks.rb')
    end

  end
end
