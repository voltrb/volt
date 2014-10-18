class TodosController < Volt::ModelController
  model :page

  def add_todo
    self._todos << {name: self._new_todo}
    self._new_todo = ''
  end

  def remove_todo(todo)
    self._todos.delete(todo)
  end

  def completed
    self._todos.count {|t| t._completed }
  end

end
