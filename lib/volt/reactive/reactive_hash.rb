require 'volt/reactive/hash_dependency'

class ReactiveHash
  def initialize(values={})
    @hash = values
    @deps = HashDependency.new
    @all_deps = Dependency.new
  end

  def ==(val)
    @all_deps.depend
    @hash == val
  end

  # TODO: We should finish off this class for reactivity
  def method_missing(method_name, *args, &block)
    @all_deps.depend

    return @hash.send(method_name, *args, &block)
  end

  def [](key)
    @deps.depend(key)

    return @hash[key]
  end

  def []=(key, value)
    @deps.changed!(key)
    @all_deps.changed!

    @hash[key] = value
  end

  def delete(key)
    @deps.delete(key)
    @hash.delete(key)
  end

  def clear
    @hash.each_pair do |key,_|
      delete(key)
    end
  end

  def inspect
    "#<ReactiveHash #{@hash.inspect}>"
  end
end