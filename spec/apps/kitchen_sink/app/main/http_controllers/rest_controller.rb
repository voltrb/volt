class RestController < Volt::HttpController

  def index
    render plain: "this is just some text"
  end

end