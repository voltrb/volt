if RUBY_PLATFORM == 'opal'
  class Benchmark
    def self.bm(iterations = 1)
      puts 'BM'

      times = []
      total_time = nil
      result = nil

      iterations.times do
        start_time = `Date.now()`
        result = yield
        end_time = `Date.now()`
        total_time = `end_time - start_time`
        times << total_time
      end

      if iterations == 1
        puts "TOTAL TIME: #{total_time}ms"
      else
        puts "Times: #{times.inspect}"
      end

      result
    end
  end
end
