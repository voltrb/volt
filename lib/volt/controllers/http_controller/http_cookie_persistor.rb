require 'volt/models/persistors/base'

module Volt
  module Persistors
    class HttpCookiePersistor < Base
      attr_reader :changed_cookies

      def initialize(*args)
        super

        @changed_cookies = {}
      end

      def changed(attribute_name)
        value = @model.get(attribute_name)
        value = value.to_h if value.is_a?(Volt::Model)

        @changed_cookies[attribute_name] = value
      end
    end
  end
end