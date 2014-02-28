class ReactiveGenerator
  # Takes a hash and returns a ReactiveValue that depends on
  # any ReactiveValue's inside of the hash (or children).
  def self.from_hash(hash, skip_if_no_reactives=false)
    reactives = find_reactives(hash)

    if skip_if_no_reactives && reactives.size == 0
      # There weren't any reactives, we can just use the hash
      return hash
    else
      # Create a new reactive value that listens on all of its
      # child reactive values.
      value = ReactiveValue.new(hash)

      reactives.each do |child|
        value.reactive_manager.add_parent!(child)
      end

      return value
    end
  end

  # Recursively loop through the data, returning a list of all
  # reactive values in the hash, array, etc..
  def self.find_reactives(object)
    found = []
    if object.reactive?
      found << object

      found += find_reactives(object.cur)
    elsif object.is_a?(Array)
      object.each do |item|
        found += find_reactives(item)
      end
    elsif object.is_a?(Hash)
      object.each_pair do |key, value|
        found += find_reactives(key)
        found += find_reactives(value)
      end
    end

    return found.flatten
  end
end
