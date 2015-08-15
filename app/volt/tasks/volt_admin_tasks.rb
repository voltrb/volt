class VoltAdminTasks < Volt::Task
  def live_queries
    pool = @volt_app.live_query_pool.pool

    live_queries = []

    pool.each_pair do |collection, queries|
      if queries
        queries.each do |query, live_query|
          live_queries << live_query
        end
      end
    end

    data = live_queries.map do |lq|
      [lq.collection, lq.query]
    end

    puts "--- current query pool ---"
    puts data.map {|collection, query| "#{collection}:\t#{query.inspect}" }

    data
  end
end