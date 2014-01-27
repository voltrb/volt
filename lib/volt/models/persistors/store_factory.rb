module Persistors
  class StoreFactory
    def initialize(tasks)
      @tasks = tasks
    end
    
    def new(model)
      Store.new(model, @tasks)
    end
  end
end