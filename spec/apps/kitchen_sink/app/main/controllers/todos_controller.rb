module Main
  class TodosController < Volt::ModelController
    model :store

    def add_todo
      _todos << { name: page._new_todo }
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
