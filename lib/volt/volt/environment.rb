class Volt
  class Environment
    def initialize
      @env = ENV['VOLT_ENV'] || 'development'
    end

    def ==(val)
      @env == val
    end

    def production?
      self.==('production')
    end

    def test?
      self.==('test')
    end

    def development?
      self.==('development')
    end

    def inspect
      @env.inspect
    end
  end
end
