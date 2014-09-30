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
    # TODORW: should this .remove
    dep = @hash_depedencies[key]

    if dep
      dep.changed!
      dep.remove
    end

    @hash_depedencies.delete(key)
  end

  private
    def ensure_key(key)
      @hash_depedencies[key] ||= Dependency.new
    end
end
