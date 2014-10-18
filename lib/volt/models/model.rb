require 'volt/models/model_wrapper'
require 'volt/models/array_model'
require 'volt/models/model_helpers'
require 'volt/models/model_hash_behaviour'
require 'volt/models/validations'
require 'volt/models/model_state'
require 'volt/reactive/reactive_hash'

module Volt

  class NilMethodCall < NoMethodError
  end

  class Model
    include ModelWrapper
    include ModelHelpers
    include ModelHashBehaviour
    include Validations
    include ModelState

    attr_reader :attributes
    attr_reader :parent, :path, :persistor, :options

    def initialize(attributes = {}, options = {}, initial_state = nil)
      @deps        = HashDependency.new
      self.options = options

      send(:attributes=, attributes, true)

      # Models start in a loaded state since they are normally setup from an
      # ArrayModel, which will have the data when they get added.
      @state = :loaded

      @persistor.loaded(initial_state) if @persistor
    end

    # the id is stored in a field named _id, so we setup _id to proxy to this
    def _id
      @attributes && @attributes[:_id]
    end

    def _id=(val)
      self.__id = val
    end

    # Update the options
    def options=(options)
      @options     = options
      @parent      = options[:parent]
      @path        = options[:path] || []
      @class_paths = options[:class_paths]
      @persistor   = setup_persistor(options[:persistor])
    end

    # Assign multiple attributes as a hash, directly.
    def attributes=(attrs, initial_setup = false)
      @attributes = {}

      attrs = wrap_values(attrs)

      if attrs
        # Assign id first
        id       = attrs.delete(:_id)
        self._id = id if id

        # Assign each attribute using setters
        attrs.each_pair do |key, value|
          if self.respond_to?(:"#{key}=")
            # If a method without an underscore is defined, call that.
            send(:"#{key}=", value)
          else
            # Otherwise, use the _ version
            send(:"_#{key}=", value)
          end
        end
      else
        @attributes = attrs
      end

      # Trigger and change all
      @deps.changed_all!
      @deps = HashDependency.new

      unless initial_setup

        # Let the persistor know something changed
        if @persistor
          # the changed method on a persistor should return a promise that will
          # be resolved when the save is complete, or fail with a hash of errors.
          return @persistor.changed
        end
      end
    end

    alias_method :assign_attributes, :attributes=

    # Pass the comparison through
    def ==(val)
      if val.is_a?(Model)
        # Use normal comparison for a model
        super
      else
        # Compare to attributes otherwise
        attributes == val
      end
    end

    # Pass through needed
    def !
      !attributes
    end


    def method_missing(method_name, *args, &block)
      if method_name[0] == '_'
        if method_name[-1] == '='
          # Assigning an attribute with =
          assign_attribute(method_name, *args, &block)
        else
          read_attribute(method_name)
        end
      else
        # Call on parent
        super
      end
    end

    # Do the assignment to a model and trigger a changed event
    def assign_attribute(method_name, *args, &block)
      self.expand!
      # Assign, without the =
      attribute_name = method_name[1..-2].to_sym

      value = args[0]

      @attributes[attribute_name] = wrap_value(value, [attribute_name])

      @deps.changed!(attribute_name)

      # Let the persistor know something changed
      @persistor.changed(attribute_name) if @persistor
    end

    # When reading an attribute, we need to handle reading on:
    # 1) a nil model, which returns a wrapped error
    # 2) reading directly from attributes
    # 3) trying to read a key that doesn't exist.
    def read_attribute(method_name)
      # Reading an attribute, we may get back a nil model.
      method_name = method_name.to_sym

      if method_name[0] != '_' && @attributes == nil
        # The method we are calling is on a nil model, return a wrapped
        # exception.
        return_undefined_method(method_name)
      else
        attr_name = method_name[1..-1].to_sym
        # See if the value is in attributes
        value     = (@attributes && @attributes[attr_name])

        # Track dependency
        @deps.depend(attr_name)

        if value
          # key was in attributes or cache
          value
        else
          new_model              = read_new_model(attr_name)
          @attributes            ||= {}
          @attributes[attr_name] = new_model
          new_model
        end
      end
    end

    # Get a new model, make it easy to override
    def read_new_model(method_name)
      if @persistor && @persistor.respond_to?(:read_new_model)
        return @persistor.read_new_model(method_name)
      else
        opts = @options.merge(parent: self, path: path + [method_name])
        if method_name.plural?
          return new_array_model([], opts)
        else
          return new_model(nil, opts)
        end
      end
    end

    def return_undefined_method(method_name)
      # Methods called on nil capture an error so the user can know where
      # their nil calls are.  This error can be re-raised at a later point.
      begin
        raise NilMethodCall.new("undefined method `#{method_name}' for #{self.to_s}")
      rescue => e
        result = e

        # Cleanup backtrace
        # TODO: this could be better
        result.backtrace.reject! { |line| line['lib/models/model.rb'] || line['lib/models/live_value.rb'] }
      end
    end

    def new_model(attributes, options)
      class_at_path(options[:path]).new(attributes, options)
    end

    def new_array_model(attributes, options)
      # Start with an empty query
      options         = options.dup
      options[:query] = {}

      ArrayModel.new(attributes, options)
    end

    def trigger_by_attribute!(event_name, attribute, *passed_args)
      trigger_by_scope!(event_name, *passed_args) do |scope|
        method_name, *args, block = scope

        # TODO: Opal bug
        args                      ||= []

        # Any methods without _ are not directly related to one attribute, so
        # they should all trigger
        !method_name || method_name[0] != '_' || (method_name == attribute.to_sym && args.size == 0)
      end
    end

    # If this model is nil, it makes it into a hash model, then
    # sets it up to track from the parent.
    def expand!
      if attributes.nil?
        @attributes = {}
        if @parent
          @parent.expand!

          @parent.send(:"_#{@path.last}=", self)
        end
      end
    end

    # Initialize an empty array and append to it
    def <<(value)
      if @parent
        @parent.expand!
      else
        raise "Model data should be stored in sub collections."
      end

      # Grab the last section of the path, so we can do the assign on the parent
      path   = @path.last
      result = @parent.send(path)

      if result.nil?
        # If this isn't a model yet, instantiate it
        @parent.send(:"#{path}=", new_array_model([], @options))
        result = @parent.send(path)
      end

      # Add the new item
      result << value

      nil
    end

    def inspect
      Computation.run_without_tracking do
        "<#{self.class.to_s}:#{object_id} #{attributes.inspect}>"
      end
    end

    def save!
      # Compute the erros once
      errors = self.errors

      if errors.size == 0
        save_to = options[:save_to]
        if save_to
          if save_to.is_a?(ArrayModel)
            # Add to the collection
            new_model             = save_to << self.attributes

            # Set the buffer's id to track the main model's id
            self.attributes[:_id] = new_model._id
            options[:save_to]     = new_model

            # TODO: return a promise that resolves if the append works
          else
            # We have a saved model
            return save_to.assign_attributes(self.attributes)
          end
        else
          raise "Model is not a buffer, can not be saved, modifications should be persisted as they are made."
        end

        Promise.new.resolve({})
      else
        # Some errors, mark all fields
        self.class.validations.keys.each do |key|
          mark_field!(key.to_sym)
        end

        Promise.new.reject(errors)
      end
    end


    # Returns a buffered version of the model
    def buffer
      model_path = options[:path]

      # When we grab a buffer off of a plual class (subcollection), we get it as a model.
      if model_path.last.plural? && model_path[-1] != :[]
        model_klass = class_at_path(model_path + [:[]])
      else
        model_klass = class_at_path(model_path)
      end

      new_options = options.merge(path: model_path, save_to: self).reject { |k, _| k.to_sym == :persistor }
      model       = model_klass.new({}, new_options, :loading)

      if state == :loaded
        setup_buffer(model)
      else
        self.parent.then do
          setup_buffer(model)
        end
      end

      model
    end


    private
    def setup_buffer(model)
      model.attributes = self.attributes
      model.change_state_to(:loaded)
    end

    # Takes the persistor if there is one and
    def setup_persistor(persistor)
      if persistor
        @persistor = persistor.new(self)
      end
    end
  end
end
