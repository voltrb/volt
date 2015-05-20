# A patch to fix https://github.com/opal/opal/issues/801 until it is fixed in (0.8)
if RUBY_PLATFORM == 'opal'
  class Boolean
    def hash
      self ? 'Boolean:true' : 'Boolean:false'
    end
  end
end
