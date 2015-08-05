class Hash
  # Returns a hash excluding the keys passed in.
  def without(*keys)
    reject do |key, value|
      keys.include?(key)
    end
  end

  # multifetch - returns an array of values for the arg keys
  def mfetch(*args)
    args.map {|k| self[k] }
  end
end
