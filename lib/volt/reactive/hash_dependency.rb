class HashDependency
  def initialize
    @hash_depedencies = {}
  end

  def depend(key)
    ensure_key(key).depend
  end

  def changed!(key)
    ensure_key(key).changed!
  end

  def delete(key)
    dep = @hash_depedencies[key]

    if dep
      dep.changed!
      dep.remove
    end

    @hash_depedencies.delete(key)
  end

  def changed_all!
    @hash_depedencies.each_pair do |key,value|
      value.changed!
    end
  end

  private
    def ensure_key(key)
      @hash_depedencies[key] ||= Dependency.new
    end
end
