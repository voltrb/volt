module Volt
  # Provide methods on the model class to more easily setup user validations
  module UserValidatorHelpers
    module ClassMethods
      # Own by user assigns a user_id to
      def own_by_user(key=:user_id)
        # Setup a validation that
        validate do |old_model|
          if Volt.user_id
            # The user is logged in, assign the user_id if the model is
            # not tracking a user.
            puts "OM1: #{old_model.inspect} -- #{self.inspect}"
            if !old_model || old_model.send(:"_#{key}").blank?
              puts "CHANGE"
              send(:"_#{key}=", Volt.user_id)
              next nil
            end
          else
            # No valid user, add an error
            next {key => ['requires a logged in user']}
          end
        end
      end

      # permissions takes a block and yields
      def permissions


      end
    end

    def self.included(base)
      base.send(:extend, ClassMethods)
    end
  end



  # own_by_user
  #
  # permissions do |user_id|
  #   if owner?
  #     allow_write :field1, :field2
  #   else
  #     deny_write :field3
  #   end
  # end
  #

  class UserValidator
    def self.validate(model, old_model, field_name, args)
      errors = {}

      message = (args.is_a?(Hash) && args[:message]) || 'can not be modified by you'


    end
  end
end