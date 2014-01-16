# The tasks class provides an interface to call tasks on
# the backend server.
class Tasks
  def initialize(page)
    @page = page
  end
  
  def call(class_name, method_name, *args)
    @page.channel.send([class_name, method_name, *args])
  end
end