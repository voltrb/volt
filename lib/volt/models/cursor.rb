require 'volt/models/array_model'

module Volt
  class Cursor < ArrayModel
    # Some cursors return a value instead of an ArrayModel, in this case, we
    # store the array in the ArrayModel (so we can reuse ArrayModel's path)
    # TODO: should abstract this into a base class.
    def value=(val)
      @array = val
      @has_value = true
    end

    def value
      @array
    end

    def has_value?
      @has_value
    end
  end
end
