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

  it "should handle routes with bindings in them" do
    params = Model.new({}, persistor: Persistors::Params)

    routes do
      get '/', _controller: 'index'
      get '/blog/{_id}', _controller: 'blog'
    end

    params = @routes.params_for_path('/blog/20')
    puts params.inspect

  end
end
