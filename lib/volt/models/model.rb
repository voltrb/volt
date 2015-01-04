require 'volt/models/model_wrapper'
require 'volt/models/array_model'
require 'volt/models/model_helpers'
require 'volt/models/model_hash_behaviour'
require 'volt/models/validations'
require 'volt/models/model_state'
require 'volt/models/buffer'
require 'volt/models/field_helpers'
require 'volt/reactive/reactive_hash'
require 'volt/models/validators/user_validation'
require 'volt/models/dirty'

module Volt
  class NilMethodCall < NoMethodError
  end

  class Model
    include ModelWrapper
    include ModelHelpers
    include ModelHashBehaviour
    include Validations
    include ModelState
    include Buffer
    include FieldHelpers
    include UserValidatorHelpers
    include Dirty

    attr_reader :attributes, :parent, :path, :persistor, :options

    def initialize(attributes = {}, options = {}, initial_state = nil)
      @deps        = HashDependency.new
      @size_dep    = Dependency.new
      self.options = options

      @new = (initial_state != :loaded)

      send(:attributes=, attributes, true)

      # Models start in a loaded state since they are normally setup from an
      # ArrayModel, which will have the data when they get added.
      @state = :loaded

      @persistor.loaded(initial_state) if @persistor
    end

    # the id is stored in a field named _id, so we setup _id to proxy to this
    def _id
      __id
    end

    def _id=(val)
      self.__id = val
    end

    # Return true if the model hasn't been saved yet
    def new?
      @new
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
        id = attrs.delete(:_id)

        # When doing a mass-assign, we don't save until the end.
        Model.nosave do
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
        end
      else
        @attributes = attrs
      end

      # Trigger and change all
      @deps.changed_all!
      @deps = HashDependency.new

      # Save the changes
      run_changed unless initial_setup
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
        # Remove underscore
        method_name = method_name[1..-1]
        if method_name[-1] == '='
          # Assigning an attribute without the =
          assign_attribute(method_name[0..-2], args[0], &block)
        else
          read_attribute(method_name)
        end
      else
        # Call on parent
        super
      end
    end

    # Do the assignment to a model and trigger a changed event
    def assign_attribute(attribute_name, value, &block)
      self.expand!
      # Assign, without the =
      attribute_name = attribute_name.to_sym

      old_value = @attributes[attribute_name]
      new_value = wrap_value(value, [attribute_name])

      if old_value != new_value
        # Track the old value
        attribute_will_change!(attribute_name, old_value)

        # Assign the new value
        @attributes[attribute_name] = new_value

        @deps.changed!(attribute_name)

        if old_value == nil || new_value == nil
          @size_dep.changed!
        end

        # TODO: Can we make this so it doesn't need to be handled for non store collections
        # (maybe move it to persistor, though thats weird since buffers don't have a persistor)
        clear_server_errors(attribute_name) if @server_errors

        # Save the changes
        run_changed(attribute_name)
      end
    end

    # When reading an attribute, we need to handle reading on:
    # 1) a nil model, which returns a wrapped error
    # 2) reading directly from attributes
    # 3) trying to read a key that doesn't exist.
    def read_attribute(attr_name)
      # Reading an attribute, we may get back a nil model.
      attr_name = attr_name.to_sym

      # Track dependency
      # @deps.depend(attr_name)

      # See if the value is in attributes
      if @attributes && @attributes.key?(attr_name)
        # Track dependency
        @deps.depend(attr_name)

        return @attributes[attr_name]
      else
        new_model              = read_new_model(attr_name)
        @attributes            ||= {}
        @attributes[attr_name] = new_model

        # Trigger size change
        # TODO: We can probably improve Computations to just make this work
        # without the delay
        if Volt.in_browser?
          `setImmediate(function() {`
            @size_dep.changed!
          `});`
        else
          @size_dep.changed!
        end

        # Depend on attribute
        @deps.depend(attr_name)
        return new_model
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

    def new_model(attributes, options)
      class_at_path(options[:path]).new(attributes, options)
    end

    def new_array_model(attributes, options)
      # Start with an empty query
      options         = options.dup
      options[:query] = {}

      ArrayModel.new(attributes, options)
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
        fail 'Model data should be stored in sub collections.'
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
      "<#{self.class}:#{object_id} #{attributes.inspect}>"
    end

    # Takes a block that when run, changes to models will not save inside of
    if RUBY_PLATFORM == 'opal'
      # Temporary stub for no save on client
      def self.nosave
        yield
      end
    else
      def self.nosave
        previous = Thread.current['nosave']
        Thread.current['nosave'] = true
        begin
          yield
        ensure
          Thread.current['nosave'] = previous
        end
      end
    end

    private

    def setup_buffer(model)
      model.attributes = attributes
      model.change_state_to(:loaded)
    end

    # Takes the persistor if there is one and
    def setup_persistor(persistor)
      if persistor
        @persistor = persistor.new(self)
      end
    end

    # Called when something in the model changes.  Saves
    # the model if there is a persistor, and changes the
    # model to not be new.
    #
    # @return [Promise|nil] a promise for when the save is
    #         complete
    def run_changed(attribute_name=nil)
      result = nil

      # Buffers don't save on changes.
      # Don't save right now if we're in a nosave block
      if !buffer? && (!defined?(Thread) || !Thread.current['nosave'])
        # First check that all local validations pass
        if errors.size > 0
          # Some errors are present, revert changes
        else
          # No errors, tell the persistor to handle the change (usually save)

          # the changed method on a persistor should return a promise that will
          # be resolved when the save is complete, or fail with a hash of errors.
          result = @persistor.changed(attribute_name) if @persistor
          @new = false
        end
      end

      return result
    end
  end
end
