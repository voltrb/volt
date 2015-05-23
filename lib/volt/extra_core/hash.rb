class Hash
  # Returns a hash excluding the keys passed in.
  def without(*keys)
    reject do |key, value|
      keys.include?(key)
    end
  end
end
