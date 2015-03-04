module Volt
  # Provide methods on the model class to more easily setup user validations
  module UserValidatorHelpers
    module ClassMethods
      # Own by user requires a logged in user (Volt.user) to save a model.  If
      # the user is not logged in, an validation error will occur.  Once created
      # the user can not be changed.
      #
      # @param key [Symbol] the name of the attribute to store
      def own_by_user(key=:user_id)
        # When the model is created, assign it the user_id (if the user is logged in)
        on(:new) do
          if (user_id = Volt.user_id)
            send(:"_#{key}=", user_id)
          end
        end

        on(:create, :update) do
          # Don't allow the key to be changed
          deny(key)
        end

        # Setup a validation that requires a user_id
        validate do
          unless _user_id
            # Show an error that the user is not logged in
            next {key => ['requires a logged in user']}
          end
        end
      end


      # TODO: Change to
      # permissions(:create, :read, :update) do |action|
      #   if owner?
      #     allow
      #   else
      #     deny :user_id
      #   end
      # end

      # permissions takes a block and yields
      def permissions(*actions, &block)
        # Store the permissions block so we can run it in validations
        self.__permissions__ ||= {}

        # if no action was specified, assume all actions
        actions += [:create, :read, :update, :delete] if actions.size == 0

        actions.each do |action|
          # Add to an array of proc's for each action
          (self.__permissions__[action] ||= []) << block
        end

        validate do
          run_permissions
        end
      end
    end

    def self.included(base)
      base.send(:extend, ClassMethods)
      base.class_attribute :__permissions__
    end

    def allow(*fields)
      if @__allow_fields
        if @__allow_fields != true
          if fields.size == 0
            # No field's were passed, this means we deny all
            @__allow_fields = true
          else
            # Fields were specified, add them to the list
            @__allow_fields += fields.map(&:to_sym)
          end
        end
      else
        raise "allow should be called inside of a permissions block"
      end
    end

    def deny(*fields)
      if @__deny_fields
        if @__deny_fields != true
          if fields.size == 0
            # No field's were passed, this means we deny all
            @__deny_fields = true
          else
            # Fields were specified, add them to the list
            @__deny_fields += fields.map(&:to_sym)
          end
        end
      else
        raise "deny should be called inside of a permissions block"
      end
    end

    # owner? can be called on a model to check if the currently logged
    # in user (```Volt.user```) is the owner of this instance.
    #
    # @param key [Symbol] the name of the attribute where the user_id is stored
    def owner?(key=:user_id)
      send(:"_#{key}") == Volt.user_id
    end

    # Returns boolean if the model can be deleted
    def can_delete?
      action_allowed?(:delete)
    end

    # Checks the read permissions
    def can_read?
      action_allowed?(:read)
    end

    def can_create?
      action_allowed?(:create)
    end

    # Checks if any denies are in place for an action (read or delete)
    def action_allowed?(action_name)
      # TODO: this does some unnecessary work
      compute_allow_and_deny(action_name)

      deny = @__deny_fields == true || @__deny_fields.size > 0

      clear_allow_and_deny

      return !deny
    end

    private
    def run_permissions(action_name=nil)
      compute_allow_and_deny(action_name)

      errors = {}

      if @__allow_fields == true
        # Allow all fields
      elsif @__allow_fields.size > 0
        # Deny all not specified in the allow list
        changed_attributes.keys.each do |field_name|
          unless @__allow_fields.include?(field_name)
            add_error_if_changed(errors, field_name)
          end
        end
      end

      if @__deny_fields == true
        # Don't allow any field changes
        changed_attributes.keys.each do |field_name|
          add_error_if_changed(errors, field_name)
        end
      else
        # Allow all except the denied
        @__deny_fields.each do |field_name|
          if changed?(field_name)
            add_error_if_changed(errors, field_name)
          end
        end
      end

      clear_allow_and_deny

      errors
    end

    def clear_allow_and_deny
      @__deny_fields = nil
      @__allow_fields = nil
    end

    # Run through the permission blocks for the action name, acumulate
    # all allow/deny fields.
    def compute_allow_and_deny(action_name)
      @__deny_fields = []
      @__allow_fields = []

      # Run the permission blocks
      action_name ||= new? ? :create : :update

      puts "COMPUTE ALL/DENY for #{action_name.inspect} - #{self.class.__permissions__.inspect} - #{self.inspect}"
      # Run each of the permission blocks for this action
      permissions = self.class.__permissions__
      if permissions && (blocks = permissions[action_name])
        blocks.each do |block|
          # Call the block, pass the action name
          instance_exec(action_name, &block)
        end
      end

    end

    def add_error_if_changed(errors, field_name)
      if changed?(field_name)
        (errors[field_name] ||= []) << 'can not be changed'
      end
    end
  end
end
