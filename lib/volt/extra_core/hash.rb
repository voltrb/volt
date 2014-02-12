class Hash
  def deep_cur
    new_hash = {}
    
    each_pair do |key, value|
      new_hash[key.deep_cur] = value.deep_cur
    end
    
    return new_hash
  end
end