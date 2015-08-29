require 'json'

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
        elsif obj.size == 1 && (time = obj['$date'])
          if time.is_a?(Fixnum)
            return Time.at(time / 1000.0)
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
            key = '$escape'
            value = {'$date' => encode(value)}
          else
            value = encode(value)
          end

          [key, value]
        end.to_h
      elsif Time === obj
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