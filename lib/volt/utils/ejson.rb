require 'json'

module Volt
  class EJSON
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
      else
        if obj.is_a?(Time)
          {'$date' => obj.to_i * 1_000}
        else
          obj
        end
      end
    end
  end
end