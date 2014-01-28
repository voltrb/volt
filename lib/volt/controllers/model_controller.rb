class ModelController
  def initialize
    self.model = @@default_model
  end
  
  def self.model(val)
    @@default_model = val
  end
  
  # Sets the current model on this controller
  def model=(val)
    if val.is_a?(Symbol) || val.is_a?(String)
      collections = [:page, :store, :params]
      if collections.include?(val.to_sym)
        @model = self.send(val)
      else
        raise "#{val} is not the name of a valid model, choose from: #{collections.join(', ')}"
      end
    else
      @model = model
    end
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
  
  def tasks
    $page.tasks
  end
  
  def controller
    @controller ||= ReactiveValue.new(Model.new)
  end

  def method_missing(method_name, *args, &block)
    return @model.send(method_name, *args, &block)      
  end
end