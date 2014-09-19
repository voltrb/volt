class TaskHandler
  def self.method_missing(name, *args, &block)
    $page.tasks.call(self.name, name, *args, &block)
  end
end