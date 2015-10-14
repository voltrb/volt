require 'volt/helpers/time'

module Main
  class TodosController < Volt::ModelController
    model :store

    def add_todo
      created_at = Volt::VoltTime.new
      _todos << { name: page._new_todo, created_at: Volt::VoltTime.new }
      page._new_todo = ''
    end

    def remove_todo(todo)
      todo.destroy
    end

    def completed
      _todos.count(&:_completed)
    end
  end
end
