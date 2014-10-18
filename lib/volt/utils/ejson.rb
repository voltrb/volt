module Volt
  class EJson
    def self.dump_as(obj)
      obj
    end

    def self.dump(obj)
      JSON.dump(dump_as(obj))
    end
  end
end
