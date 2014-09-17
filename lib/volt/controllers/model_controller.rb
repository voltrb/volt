require 'volt/reactive/reactive_accessors'

class ModelController
  include ReactiveAccessors

  def self.model(val)
    @default_model = val
  end

  # Sets the current model on this controller
  def model=(val)
    # Start with a nil reactive value.
    @model ||= ReactiveValue.new(Proc.new { nil })

    if Symbol === val || String === val
      collections = [:page, :store, :params, :controller]
      if collections.include?(val.to_sym)
        @model = self.send(val)
      else
        raise "#{val} is not the name of a valid model, choose from: #{collections.join(', ')}"
      end
    elsif val
      @model = val
    else
      raise "model can not be #{val.inspect}"
    end
  end

  def model
    @model
  end

  def self.new(*args, &block)
    inst = self.allocate

    inst.model = (@default_model || :controller)

    inst.initialize(*args, &block)

    return inst
  end

  def initialize(*args)


    # Set the instance variable to match any passed in arguments
    if args.size > 0
      args[0].each_pair do |key, value|
        instance_variable_set(:"@#{key}", value)
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
