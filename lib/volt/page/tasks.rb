# The tasks class provides an interface to call tasks on
# the backend server.
class Tasks
  def initialize(page)
    @page = page
    
    page.channel.on('message') do |*args|
      received_message(*args)
    end
  end
  
  def call(class_name, method_name, *args, &block)
    @page.channel.send([class_name, method_name, *args])
  end
  
  
  def received_message(name, *args)
    if name == 'update'
      update(*args)
    end
  end
  
  def update(path, values)
    # Store.assign_
    $page.store.send(:"#{path}=", values)
    puts "Update: #{path.inspect} - #{values.inspect}"
  end
end