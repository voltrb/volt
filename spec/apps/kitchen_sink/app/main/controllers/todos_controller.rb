class TodosController < Volt::ModelController
  model :page

  def add_todo
    _todos << { name: _new_todo }
    self._new_todo = ''
  end

  def remove_todo(todo)
    _todos.delete(todo)
  end

  def completed
    _todos.count(&:_completed)
  end
end
