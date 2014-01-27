require 'volt/models/persistors/base'

module Persistors
  class Store < Base
    def initialize(model)
      @model = model
    end
    
    def changed(attribute_name)
      puts "Model Changed to: #{@model.attributes} on #{attribute_name}"
    end
    
    def added
      puts "Added"
    end
  end
end