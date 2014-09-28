require 'volt/reactive/hash_dependency'

class ReactiveHash
  def initialize(values={})
    @hash = values
    @deps = HashDependency.new
  end

  def [](key)
    @deps.depend(key)

    return @hash[key]
  end

  def []=(key, value)
    @deps.changed!(key)

    @hash[key] = value
  end
end