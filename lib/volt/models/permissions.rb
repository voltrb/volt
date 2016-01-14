module Volt
  class Model
    # The permissions module provides helpers for working with Volt permissions.
    module Permissions
      module ClassMethods
        # Own by user requires a logged in user (Volt.current_user) to save a model.  If
        # the user is not logged in, an validation error will occur.  Once created
        # the user can not be changed.
        #
        # @param key [Symbol] the name of the attribute to store
        def own_by_user(key = :user_id)
          relation, pattern = key.to_s, /_id$/
          if relation.match(pattern)
            belongs_to key.to_s.gsub(pattern, '')
          else
            raise "You tried to auto associate a model using #{key}, but #{key} "\
                  "does not end in `_id`"
          end          # When the model is created, assign it the user_id (if the user is logged in)
          on(:new) do
            # Only assign the user_id if there isn't already one and the user is logged in.
            if get(:user_id).nil? && !(user_id = Volt.current_user_id).nil?
              set(key, user_id)
            end
          end

          permissions(:update) do
            # Don't allow the key to be changed
            deny(key)
          end

          # Setup a validation that requires a user_id
          validate do
            # Lookup directly in @attributes to optimize and prevent the need
            # for a nil model.
            unless @attributes[:user_id]
              # Show an error that the user is not logged in
              next { key => ['requires a logged in user'] }
            end
          end
        end

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
            action = new? ? :create : :update
            run_permissions(action)
          end
        end
      end

      def self.included(base)
        base.send(:extend, ClassMethods)
        base.class_attribute :__permissions__
      end

      def allow(*fields)
        rule :allow, *fields
      end

      def deny(*fields)
        rule :deny, *fields
      end

      def rule(type, *fields)
        if @__permission_fields[type]
          if @__permission_fields[type] != true
            if fields.size == 0
              # No fields were passed, this means we [allow|deny] all
              @__permission_fields[type] = true
            else
              # Fields were specified, add them to the list
              @__permission_fields[type] += fields.map(&:to_sym)
            end
          end
        else
          fail "#{type.to_s} should be called inside of a permissions block"
        end
      end

      # owner? can be called on a model to check if the currently logged
      # in user (```Volt.current_user```) is the owner of this instance.
      #
      # @param key [Symbol] the name of the attribute where the user_id is stored
      def owner?(key = :user_id)
        # Lookup the original user_id
        owner_id = was(key) || send(:"_#{key}")
        !owner_id.nil? && owner_id == Volt.current_user_id
      end

      [:create, :update, :read, :delete].each do |action|
        # Each can_action? (can_delete? for example) returns a promise that
        # resolves to true or false if the user
        define_method(:"can_#{action}?") do
          action_allowed?(action)
        end
      end

      # Checks if any denies are in place for an action (read or delete)
      def action_allowed?(action_name)
        # TODO: this does some unnecessary work
        compute_allow_and_deny(action_name).then do

          deny = @__permission_fields[:deny] == true || (@__permission_fields[:deny] && @__permission_fields[:deny].size > 0)

          clear_allow_and_deny

          !deny
        end
      end

      # Return the list of allowed fields
      def allow_and_deny_fields(action_name)
        compute_allow_and_deny(action_name).then do

          result = [@__permission_fields[:allow], @__permission_fields[:deny]]

          clear_allow_and_deny

          result
        end
      end

      # Filter fields returns the attributes with any denied or not allowed fields
      # removed based on the current user.
      #
      # Run with Volt.as_user(...) to change the user
      def filtered_attributes
        # Run the read permission check
        allow_and_deny_fields(:read).then do |allow, deny|

          result = nil

          if allow && allow != true && allow.size > 0
            # always keep id
            allow << :id

            # Only keep fields in the allow list
            result = @attributes.select { |key| allow.include?(key) }
          elsif deny == true
            # Only keep id
            # TODO: Should this be a full reject?
            result = @attributes.reject { |key| key != :id }
          elsif deny && deny.size > 0
            # Reject any in the deny list
            result = @attributes.reject { |key| deny.include?(key) }
          else
            result = @attributes
          end

          # Deeply filter any nested models
          result.then do |res|
            keys = []
            values = []
            res.each do |key, value|
              if value.is_a?(Model)
                value = value.filtered_attributes
              end
              keys << key
              values << value
            end

            Promise.when(*values).then do |values|
              keys.zip(values).to_h
            end
          end
        end
      end

      private

      def run_permissions(action_name = nil)
        compute_allow_and_deny(action_name).then do

          errors = {}

          if @__permission_fields[:allow] == true
            # Allow all fields
          elsif @__permission_fields[:allow] && @__permission_fields[:allow].size > 0
            # Deny all not specified in the allow list
            changed_attributes.keys.each do |field_name|
              unless @__permission_fields[:allow].include?(field_name)
                add_error_if_changed(errors, field_name)
              end
            end
          end

          if @__permission_fields[:deny] == true
            # Don't allow any field changes
            changed_attributes.keys.each do |field_name|
              add_error_if_changed(errors, field_name)
            end
          elsif @__permission_fields[:deny]
            # Allow all except the denied
            @__permission_fields[:deny].each do |field_name|
              add_error_if_changed(errors, field_name) if changed?(field_name)
            end
          end

          clear_allow_and_deny

          errors
        end
      end

      def clear_allow_and_deny
        @__permission_fields[:deny] = nil
        @__permission_fields[:allow] = nil
      end

      # Run through the permission blocks for the action name, acumulate
      # all allow/deny fields.
      def compute_allow_and_deny(action_name)
        @__permission_fields ||= {}
        @__permission_fields[:deny] = []
        @__permission_fields[:allow] = []

        # Skip permissions can be run on the server to ignore the permissions
        return if Volt.in_mode?(:skip_permissions)

        # Run the permission blocks
        action_name ||= new? ? :create : :update

        # Run each of the permission blocks for this action
        permissions = self.class.__permissions__
        if permissions && (blocks = permissions[action_name])
          results = blocks.map do |block|
            # Call the block, pass the action name
            instance_exec(action_name, &block)
          end

          # Wait for any promises returned
          Promise.when(*results)
        end
      end

      def add_error_if_changed(errors, field_name)
        if changed?(field_name)
          (errors[field_name] ||= []) << 'can not be changed'
        end
      end
    end
  end
end
