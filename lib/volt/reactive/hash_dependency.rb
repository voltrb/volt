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

  private
    def ensure_key(key)
      @hash_depedencies[key] ||= Dependency.new
    end
end
