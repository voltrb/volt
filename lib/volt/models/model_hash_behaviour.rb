# Contains all of the methods on a model that make it behave like a hash.
# Moving this into a module cleans up the main Model class for things that
# make it behave like a model.
module ModelHashBehaviour
  def self.included(base)
    # In modules, since we need to tag on the main class, we setup the
    # tags with included.
    base.tag_method(:delete) do
      destructive!
    end

    base.tag_method(:clear) do
      destructive!
    end
  end


  def nil?
    attributes.nil?
  end

  def false?
    attributes.false?
  end

  def true?
    attributes.true?
  end

  def delete(name)
    name = name.to_sym
    __clear_element(name)
    value = attributes.delete(name)
    trigger_by_attribute!('changed', name)

    @persistor.removed(name) if @persistor

    return value
  end


  def clear
    attributes.each_pair do |key,value|
      __clear_element(key)
    end

    attributes.clear
    trigger!('changed')

    @persistor.removed(nil) if @persistor
  end


  # Convert the model to a hash all of the way down.
  def to_h
    hash = {}
    attributes.each_pair do |key, value|
      hash[key] = deep_unwrap(value)
    end

    return hash
  end

end
