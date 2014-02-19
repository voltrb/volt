require 'volt/router/routes'
require 'volt/models'

def routes(&block)
  @routes = Routes.new
  @routes.define(&block)
end

describe Routes do
  it "should match routes" do
    params = Model.new({}, persistor: Persistors::Params)
    params._controller = 'blog'
    params._index = '5'

    routes do
      get '/', _controller: 'index'
      get '/blog', _controller: 'blog'
    end

    path, cleaned_params = @routes.url_for_params(params)
    expect(path).to eq('/blog')
    expect(cleaned_params).to eq({_index: '5'})
  end
end
