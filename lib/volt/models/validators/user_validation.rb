module Volt
  # UserValidator gives you two



  own_by_user

  permissions do |user_id|
    if owner?
      allow_write :field1, :field2
    else
      deny_write :field3
    end
  end


  class UserValidator
    def self.validate(model, old_model, field_name, args)
      errors = {}

      message = (args.is_a?(Hash) && args[:message]) || 'can not be modified by you'


    end
  end
end