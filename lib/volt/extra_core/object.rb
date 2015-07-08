require 'volt/utils/ejson'

class Object
  # Setup a default pretty_inspect
  # alias_method :pretty_inspect, :inspect

  def instance_values
    Hash[instance_variables.map { |name| [name[1..-1], instance_variable_get(name)] }]
  end

  def html_inspect
    inspect.gsub('<', '&lt;').gsub('>', '&gt;')
  end

  # TODO: Need a real implementation of this
  def deep_clone
    if RUBY_PLATFORM == 'opal'
      Volt::EJSON.parse(Volt::EJSON.stringify(self))
    else
      Marshal.load(Marshal.dump(self))
    end
  end

  # Convert a non-promise value into a resolved promise.  Resolve the block if
  # it takes one.
  def then(&block)
    promisify_and_run_method(:then, &block)
  end

  # def fail(&block)
  #   promisify_and_run_method(:fail, &block)
  # end

  def try(*a, &b)
    if a.empty? && block_given?
      yield self
    else
      public_send(*a, &b) if respond_to?(a.first)
    end
  end

  private
  def promisify_and_run_method(method_name, &block)
    promise = Promise.new.resolve(self)

    promise = promise.send(method_name, &block) if block

    promise
  end
end
