# DestructiveMethods tracks the names of all methods that are marked as
# destructive.  This lets us do an optimization where we don't need to
# check any methods with names that aren't here, we can be sure that they
# are not destructive.  If the method is tracked here, we need to check
# it on its current class.
class DestructiveMethods
  @@method_names = {}

  def self.add_method(method_name)
    @@method_names[method_name] = true
  end

  # Check to see if a method might be destructive.  If this returns
  # false, then we can guarentee that it won't be destructive and
  # we can skip a destructive check.
  def self.might_be_destructive?(method_name)
    return @@method_names[method_name]
  end
end
