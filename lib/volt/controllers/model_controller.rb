require 'volt/reactive/reactive_accessors'

class ModelController
  include ReactiveAccessors

  reactive_accessor :current_model

  def self.model(val)
    @default_model = val
  end

  # Sets the current model on this controller
  def model=(val)
    # Start with a nil reactive value.
    self.current_model ||= Model.new

    if Symbol === val || String === val
      collections = [:page, :store, :params, :controller]
      if collections.include?(val.to_sym)
        self.current_model = self.send(val)
      else
        raise "#{val} is not the name of a valid model, choose from: #{collections.join(', ')}"
      end
    elsif val
      self.current_model = val
    else
      raise "model can not be #{val.inspect}"
    end
  end

  def model
    model = self.current_model

    # If the model is a proc, call it now
    if model.is_a?(Proc)
      model = model.call
    end

    return model
  end

  def self.new(*args, &block)
    inst = self.allocate

    inst.model = (@default_model || :controller)

    inst.initialize(*args, &block)

    return inst
  end

  attr_accessor :attrs

  def initialize(*args)
    if args[0]
      # Assign the first passed in argument to attrs
      self.attrs = args[0]

      # If a model attribute is passed in, we assign it directly
      if attrs.respond_to?(:model)
        self.model = attrs.locals[:model]
      end
    end
  end

  # Change the url params, similar to redirecting to a new url
  def go(url)
    self.url.parse(url)
  end

  def page
    $page.page
  end

  def paged
    $page.page
  end

  def store
    $page.store
  end

  def flash
    $page.flash
  end

  def params
    $page.params
  end

  def local_store
    $page.local_store
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
    @controller ||= Model.new
  end

  def method_missing(method_name, *args, &block)
    return model.send(method_name, *args, &block)
  end
end
