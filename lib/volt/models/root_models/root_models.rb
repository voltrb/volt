# When you get the root of a collection (.store, .page, etc...), it gives you
# back a unique class depending on the collection.  This allows you to add
# things to the root easily.
#
# The name of the model will be {CollectionName}Root.  All root model classes
# inherit from BaseRootModel, which provides methods to access the model's
# from the root.  (store.items if you have an Item model for example)

# Create a model that is above all of the root models.
class BaseRootModel < Volt::Model
end


ROOT_MODEL_NAMES = [:Store, :Page, :Params, :Cookies, :LocalStore, :Flash]

ROOT_MODEL_NAMES.each do |base_name|
  Object.const_set("#{base_name}Root", Class.new(BaseRootModel))
end

module Volt
  class RootModels
    class_attribute :model_classes
    self.model_classes = []

    def self.add_model_class(klass)
      self.model_classes << klass

      method_name = klass.to_s.underscore.pluralize

      # Create a getter for each model class off of root.
      BaseRootModel.send(:define_method, method_name) do
        get(method_name)
      end
    end
  end
end
