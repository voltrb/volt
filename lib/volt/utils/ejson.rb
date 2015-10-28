require 'json'

# We auto require time on the server, so we can decode VoltTime's in the parent
# process on the ForkingServer.  (Since no user code is booted in the forking
# server).  On the client the user has to require it if they want to use it.
unless RUBY_PLATFORM == 'opal'
  require 'volt/helpers/time'
end

module Volt
  class EJSON
    class NonEjsonType < Exception ; end

    OTHER_VALID_CLASSES = [String, Symbol, TrueClass, FalseClass, Numeric, NilClass]

    def self.stringify(obj)
      encode(obj).to_json
    end

    def self.parse(str)
      decode(JSON.parse(str))
    end

    private

    def self.decode(obj)
      if Array === obj
        obj.map {|v| decode(v) }
      elsif Hash === obj
        if obj.size == 1 && (escape = obj['$escape'])
          return escape.map do |key, value|
            [key, decode(value)]
          end.to_h
        elsif obj.size == 1
          if (time = obj['$date'])
            if defined?(VoltTime)
              if time.is_a?(Numeric)
                return VoltTime.at(time / 1000.0)
              end
            else
              raise "VoltTime is not defined, be sure to require 'volt/helpers/time'."
            end
          end
        end

        obj.map do |key, value|
          [key, decode(value)]
        end.to_h
      else
        obj
      end
    end

    def self.encode(obj)
      if Array === obj
        obj.map {|v| encode(v) }
      elsif Hash === obj
        obj.map do |key, value|
          if key == '$date'
            value = {key => encode(value)}
            key = '$escape'
          else
            value = encode(value)
          end

          [key, value]
        end.to_h
      elsif (defined?(VoltTime) && VoltTime === obj)
        {'$date' => obj.to_i * 1_000}
      elsif OTHER_VALID_CLASSES.any? {|klass| obj.is_a?(klass) }
        obj
      else
        # Not a valid class for serializing, raise an exception
        raise NonEjsonType, "Unable to serialize #{obj.inspect} to EJSON"
      end
    end
  end
end
