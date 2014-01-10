class ModelController
  def initialize(model=nil)
    @model = model
  end
  
  def page
    $page.page
  end

  def store
    $page.store
  end

  def params
    $page.params 
  end

  def url
    $page.url 
  end
  
  def channel
    $page.channel
  end
  
  def controller
    @controller ||= ReactiveValue.new(Model.new)
  end

  def method_missing(method_name, *args, &block)
    return @model.send(method_name, *args, &block)      
  end
end