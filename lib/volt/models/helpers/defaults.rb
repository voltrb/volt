module Volt
  module Models
    module Helpers
      module Defaults
        def setup_defaults
          self.class.defaults.each_pair do |field_name, default_value|
            unless @attributes.has_key?(field_name)
              @attributes[field_name] = default_value
            end
          end
        end
      end
    end
  end
end
