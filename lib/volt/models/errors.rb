require 'volt/reactive/reactive_hash'

module Volt
  class Errors < ReactiveHash
    def add(field, error)
      field_errors = (self[field] ||= [])
      field_errors << error unless field_errors.include?(error)
    end

    # Merge another set of errors in
    def merge!(errors)
      if errors
        errors.each_pair do |field, messages|
          messages.each do |message|
            add(field, message)
          end
        end
      end
    end
  end
end