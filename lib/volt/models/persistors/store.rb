require 'volt/models/persistors/base'
require 'volt/models/persistors/model_identity_map'

module Persistors
  class Store < Base

    @@identity_map = ModelIdentityMap.new

    def initialize(model, tasks=nil)
      @tasks = tasks
      @model = model

      @saved = false
    end

    def saved?
      @saved
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
        model = @model.new_model(nil, options)

        @model.attributes ||= {}
        @model.attributes[method_name] = model
      end


      return model
    end
  end
end
