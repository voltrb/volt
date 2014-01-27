require 'volt/models/persistors/base'

module Persistors
  class Store < Base
    def initialize(model, tasks=nil)
      @model = model
      @is_tracking = false
      @tasks = tasks
    end

    # On stores, we store the model so we don't have to look it up
    # every time we do a read.
    def read_new_model(method_name)
      # On stores, plural associations are automatically assumed to be
      # collections.
      options = @model.options.merge(parent: @model, path: @model.path + [method_name])
      if method_name.plural?
        model = @model.new_array_model([], options)
      else
        model = @model.new_model({}, options)
      end
    
      @model.attributes ||= {}
      @model.attributes[method_name] = model

      # if model.is_a?(StoreArray)# && model.state == :not_loaded
      #   model.load!
      # end
    
      return model
    end
  end
end