require 'volt/models/model_wrapper'
require 'volt/models/array_model'
require 'volt/models/model_helpers'
require 'volt/models/model_hash_behaviour'
require 'volt/models/validations'
require 'volt/utils/modes'
require 'volt/models/state_manager'
require 'volt/models/state_helpers'
require 'volt/models/buffer'
require 'volt/models/field_helpers'
require 'volt/reactive/reactive_hash'
require 'volt/models/validators/user_validation'
require 'volt/models/dirty'
require 'volt/models/listener_tracker'
require 'volt/models/permissions'
require 'volt/models/associations'
require 'volt/reactive/class_eventable'
require 'volt/utils/event_counter'
require 'volt/reactive/reactive_accessors'
require 'thread'

module Volt
  class NilMethodCall < NoMethodError
  end

  # The error is raised when a reserved field name is used in a
  # volt model.
  class InvalidFieldName < StandardError
  end

  class Model
    include ModelWrapper
    include ModelHelpers
    include ModelHashBehaviour
    include StateManager
    include StateHelpers
    include Validations
    include Buffer
    include FieldHelpers
    include UserValidatorHelpers
    include Dirty
    include ClassEventable
    include Modes
    include ListenerTracker
    include Permissions
    include Associations
    include ReactiveAccessors

    attr_reader :attributes, :parent, :path, :persistor, :options

    INVALID_FIELD_NAMES = {
      attributes: true,
      parent: true,
      path: true,
      options: true,
      persistor: true
    }

    def initialize(attributes = {}, options = {}, initial_state = nil)
      # The listener event counter keeps track of how many computations are listening on this model
      @listener_event_counter = EventCounter.new(
        -> { parent.try(:persistor).try(:listener_added) },
        -> { parent.try(:persistor).try(:listener_removed) }
      )

      # The root dependency is used to track if anything is using the data from this
      # model.  That information is relayed to the ArrayModel so it knows when it can
      # stop subscribing.
      # @root_dep    = Dependency.new(@listener_event_counter.method(:add), @listener_event_counter.method(:remove))
      @root_dep    = Dependency.new(-> { add_list }, -> { remove_list })

      @deps        = HashDependency.new
      @size_dep    = Dependency.new
      self.options = options

      @new = (initial_state != :loaded)

      assign_attributes(attributes, true)

      # The persistor is usually responsible for setting up the loaded_state, if
      # there is no persistor, we set it to loaded
      if @persistor
        @persistor.loaded(initial_state)
      else
        change_state_to(:loaded_state, initial_state || :loaded, false)
      end

      # Trigger the new event, pass in :new
      trigger!(:new, :new)
    end

    def add_list
      @listener_event_counter.add
    end

    def remove_list
      @listener_event_counter.remove
    end

    def state_for(*args)
      @root_dep.depend
      super
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

    alias_method :new_record?, :new?

    # Update the options
    def options=(options)
      @options     = options
      @parent      = options[:parent]
      @path        = options[:path] || []
      @class_paths = options[:class_paths]
      @persistor   = setup_persistor(options[:persistor])
    end

    # Assign multiple attributes as a hash, directly.
    def assign_attributes(attrs, initial_setup = false, skip_changes = false)
      @attributes ||= {}

      attrs = wrap_values(attrs)

      if attrs
        # When doing a mass-assign, we don't validate or save until the end.
        if initial_setup || skip_changes
          Model.no_change_tracking do
            assign_all_attributes(attrs, skip_changes)
          end
        else
          assign_all_attributes(attrs)
        end
      else
        # Assign to nil
        @attributes = attrs
      end

      # Trigger and change all
      @deps.changed_all!
      @deps = HashDependency.new

      # Save the changes
      if initial_setup
        # Run initial validation
        if Volt.in_mode?(:no_validate)
          # No validate, resolve nil
          Promise.new.resolve(nil)
        else
          return validate!.then do |errs|
            if errs && errs.size > 0
              Promise.new.reject(errs)
            else
              Promise.new.resolve(nil)
            end
          end
        end
      else
        return run_changed
      end
    end

    alias_method :attributes=, :assign_attributes

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
          set(method_name[0..-2], args[0], &block)
        else
          # If the method has an ! on the end, then we assign an empty
          # collection if no result exists already.
          expand = (method_name[-1] == '!')
          method_name = method_name[0..-2] if expand

          get(method_name, expand)
        end
      else
        # Call on parent
        super
      end
    end

    # Do the assignment to a model and trigger a changed event
    def set(attribute_name, value, &block)
      # Assign, without the =
      attribute_name = attribute_name.to_sym

      check_valid_field_name(attribute_name)

      old_value = @attributes[attribute_name]
      new_value = wrap_value(value, [attribute_name])

      if old_value != new_value
        # Track the old value, skip if we are in no_change_tracking
        attribute_will_change!(attribute_name, old_value) unless Volt.in_mode?(:no_change_tracking)

        # Assign the new value
        @attributes[attribute_name] = new_value

        @deps.changed!(attribute_name)

        @size_dep.changed! if old_value.nil? || new_value.nil?

        # TODO: Can we make this so it doesn't need to be handled for non store collections
        # (maybe move it to persistor, though thats weird since buffers don't have a persistor)
        clear_server_errors(attribute_name) if @server_errors.present?

        # Save the changes
        run_changed(attribute_name) unless Volt.in_mode?(:no_change_tracking)
      end

      new_value
    end

    # When reading an attribute, we need to handle reading on:
    # 1) a nil model, which returns a wrapped error
    # 2) reading directly from attributes
    # 3) trying to read a key that doesn't exist.
    def get(attr_name, expand = false)
      # Reading an attribute, we may get back a nil model.
      attr_name = attr_name.to_sym

      check_valid_field_name(attr_name)

      # Track that something is listening
      @root_dep.depend

      # Track dependency
      @deps.depend(attr_name)

      # See if the value is in attributes
      if @attributes && @attributes.key?(attr_name)
        return @attributes[attr_name]
      else
        # If we're expanding, or the get is for a collection, in which
        # case we always expand.
        plural_attr = attr_name.plural?
        if expand || plural_attr
          new_value = read_new_model(attr_name)

          # A value was generated, store it
          if new_value
            # Assign directly.  Since this is the first time
            # we're loading, we can just assign.
            #
            # Don't track changes if we're setting a collection
            Volt.run_in_mode_if(plural_attr, :no_change_tracking) do
              set(attr_name, new_value)
            end
          end

          return new_value
        else
          return nil
        end
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      method_name.to_s.start_with?('_') || super
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
          return new_model({}, opts)
        end
      end
    end

    def new_model(*args)
      Volt::Model.class_at_path(options[:path]).new(*args)
    end

    def new_array_model(attributes, options)
      # Start with an empty query
      options         = options.dup
      options[:query] = []

      ArrayModel.new(attributes, options)
    end

    def inspect
      Computation.run_without_tracking do
        str = "<#{self.class}:#{object_id}"

        # Get path, loaded_state, and persistor, but cache in local var
        path = self.path
        str += " path:#{path}" if path

        loaded_state = self.loaded_state
        str += " state:#{loaded_state}" if loaded_state

        persistor = self.persistor
        # str += " persistor:#{persistor.inspect}" if persistor
        str += " #{attributes.inspect}>"

        str
      end
    end

    def destroy
      if parent
        result = parent.delete(self)

        # Wrap result in a promise if it isn't one
        return Promise.new.then { result }
      else
        fail 'Model does not have a parent and cannot be deleted.'
      end
    end

    # Setup run mode helpers
    [:no_save, :no_validate, :no_change_tracking].each do |method_name|
      define_singleton_method(method_name) do |&block|
        Volt.run_in_mode(method_name, &block)
      end
    end

    private

    # Volt provides a few access methods to get more data about the model,
    # we want to prevent these from being assigned or accessed through
    # underscore methods.
    def check_valid_field_name(name)
      if INVALID_FIELD_NAMES[name]
        fail InvalidFieldName, "`#{name}` is reserved and can not be used as a field"
      end
    end

    def setup_buffer(model)
      Volt::Model.no_validate do
        model.assign_attributes(attributes, true)
      end

      model.change_state_to(:loaded_state, :loaded)

      # Set new to the same as the main model the buffer is from
      model.instance_variable_set('@new', @new)
    end

    # Takes the persistor if there is one and
    def setup_persistor(persistor)
      @persistor = persistor.new(self) if persistor
    end

    # Used internally from other methods that assign all attributes
    def assign_all_attributes(attrs, track_changes = false)
      # Assign each attribute using setters
      attrs.each_pair do |key, value|
        key = key.to_sym

        # Track the change, since assign_all_attributes runs with no_change_tracking
        old_val = @attributes[key]
        attribute_will_change!(key, old_val) if track_changes && old_val != value

        if self.respond_to?(:"#{key}=")
          # If a method without an underscore is defined, call that.
          send(:"#{key}=", value)
        else
          # Otherwise, use the _ version
          send(:"_#{key}=", value)
        end
      end
    end

    # Called when something in the model changes.  Saves
    # the model if there is a persistor, and changes the
    # model to not be new.
    #
    # @return [Promise|nil] a promise for when the save is
    #         complete
    def run_changed(attribute_name = nil)
      # no_validate mode should only be used internally.  no_validate mode is a
      # performance optimization that prevents validation from running after each
      # change when assigning multile attributes.
      unless Volt.in_mode?(:no_validate)
        # Run the validations for all fields
        result = nil
        return validate!.then do
          # Buffers are allowed to be in an invalid state
          unless buffer?
            # First check that all local validations pass
            if error_in_changed_attributes?
              # Some errors are present, revert changes
              revert_changes!

              Promise.new.reject(errors)
            else
              # No errors, tell the persistor to handle the change (usually save)

              # Don't save right now if we're in a nosave block
              unless Volt.in_mode?(:no_save)
                # the changed method on a persistor should return a promise that will
                # be resolved when the save is complete, or fail with a hash of errors.
                if @persistor
                  result = @persistor.changed(attribute_name)
                else
                  result = Promise.new.resolve(nil)
                end

                # Saved, no longer new
                @new = false

                # Clear the change tracking
                clear_tracked_changes!
              end
            end
          end

          # Return result inside of the validate! promise
          result
        end
      end

      # Didn't run validations
      nil
    end
  end
end
