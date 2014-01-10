require 'stringio'

class RequestHandler
  def call(env)
    req = Rack::Request.new(env)
    # puts env.inspect
    # puts req.inspect

    puts req.path
    req.post?
    puts req.params["data"]

    # puts "ENV: #{env.inspect}"
    [200, {"Content-Type" => "text/html"}, StringIO.new("Hello Rack!")]
  end
end