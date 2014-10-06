require 'volt/router/routes'
require 'volt/models'

def routes(&block)
  @routes = Routes.new
  @routes.define(&block)
end

describe Routes do
  it "should setup direct routes" do
    routes do
      get '/', _view: 'index'
      get '/page1', _view: 'first_page'
    end

    direct_routes = @routes.instance_variable_get(:@direct_routes)
    expect(direct_routes).to eq({"/" => {:_view => "index"}, "/page1" => {:_view => "first_page"}})
  end

  it "should setup indiect routes" do
    routes do
      get '/blog/{{ _id }}/edit', _view: 'blog/edit'
      get '/blog/{{ _id }}', _view: 'blog/show'
    end

    indirect_routes = @routes.instance_variable_get(:@indirect_routes)
    expect(indirect_routes).to eq(
      {
        "blog" => {
          "*" => {
            "edit" => {
              nil => {:_view => "blog/edit", :_id => 1}
            },
            nil => {:_view => "blog/show", :_id => 1}
          }
        }
      }
    )
  end

  it "should match routes" do
    routes do
      get "/blog", _view: 'blog'
      get '/blog/{{ _id }}', _view: 'blog/show'
      get '/blog/{{ _id }}/draft', _view: 'blog/draft', _action: 'draft'
      get '/blog/{{ _id }}/edit', _view: 'blog/edit'
      get '/blog/tags/{{ _tag }}', _view: 'blog/tag'
      get '/login/{{ _name }}/user/{{ _id }}', _view: 'login', _action: 'user'
    end

    params = @routes.url_to_params('/blog')
    expect(params).to eq({:_view => "blog"})

    params = @routes.url_to_params('/blog/55/edit')
    expect(params).to eq({:_view => "blog/edit", :_id => "55"})

    params = @routes.url_to_params('/blog/55')
    expect(params).to eq({:_view => "blog/show", :_id => "55"})

    params = @routes.url_to_params('/blog/tags/good')
    expect(params).to eq({:_view => "blog/tag", :_tag => "good"})

    params = @routes.url_to_params('/blog/55/draft')
    expect(params).to eq({:_view => "blog/draft", :_id => "55", :_action => "draft"})

    params = @routes.url_to_params('/login/jim/user/10')
    expect(params).to eq({:_view => "login", :_action => "user", :_name => "jim", :_id => "10"})

    params = @routes.url_to_params('/login/cool')
    expect(params).to eq(false)

  end

  it "should setup param matchers" do
    routes do
      get "/blog", _view: 'blog'
      get '/blog/{{ _id }}', _view: 'blog/show'
      get '/blog/{{ _id }}/edit', _view: 'blog/edit'
      get '/blog/tags/{{ _tag }}', _view: 'blog/tag'
      get '/login/{{ _name }}/user/{{ _id }}', _view: 'login', _action: 'user'
    end

    param_matches = @routes.instance_variable_get(:@param_matches)
    expect(param_matches.map {|v| v[0] }).to eq([
      {:_view => "blog"},
      {:_view => "blog/show", :_id => nil},
      {:_view => "blog/edit", :_id => nil},
      {:_view => "blog/tag", :_tag => nil},
      {:_view => "login", :_action => "user",:_name => nil, :_id => nil}
    ])

  end

  it "should go from params to url" do
    routes do
      get "/blog", _view: 'blog'
      get '/blog/{{ _id }}', _view: 'blog/show'
      get '/blog/{{ _id }}/edit', _view: 'blog/edit'
      get '/blog/tags/{{ _tag }}', _view: 'blog/tag'
      get '/login/{{ _name }}/user/{{ _id }}', _view: 'login', _action: 'user'
    end

    url, params = @routes.params_to_url({_view: 'blog/show', _id: '55'})
    expect(url).to eq('/blog/55')
    expect(params).to eq({})


    url, params = @routes.params_to_url({_view: 'blog/edit', _id: '100'})
    expect(url).to eq('/blog/100/edit')
    expect(params).to eq({})

    url, params = @routes.params_to_url({_view: 'blog/edit', _id: '100', _other: 'should_pass'})
    expect(url).to eq('/blog/100/edit')
    expect(params).to eq({_other: 'should_pass'})
  end

  it "should test that params match a param matcher" do
    routes = Routes.new
    match, params = routes.send(:check_params_match, {_view: 'blog', _id: '55'}, {_view: 'blog', _id: nil})
    expect(match).to eq(true)
    expect(params).to eq({_id: '55'})

    match, params = routes.send(:check_params_match, {_view: 'blog', _id: '55'}, {_view: 'blog', _id: '20'})
    expect(match).to eq(false)

    match, params = routes.send(:check_params_match, {_view: 'blog', _name: {_title: 'Mr', _name: 'Bob'}, _id: '55'}, {_view: 'blog', _id: nil, _name: {_title: 'Mr', _name: nil}})
    expect(match).to eq(true)
    expect(params).to eq({_id: '55'})

    # Check with an extra value _name._name
    match, params = routes.send(:check_params_match, {_view: 'blog', _name: {_title: 'Mr', _name: 'Bob'}, _id: '55'}, {_view: 'blog', _id: nil, _name: {_title: 'Mr'}})
    expect(match).to eq(true)
    expect(params).to eq({_id: '55'})

    match, params = routes.send(:check_params_match, {_view: 'blog', _name: {_title: 'Mr', _name: 'Bob'}, _id: '55'}, {_view: 'blog', _id: nil, _name: {_title: 'Phd'}})
    expect(match).to eq(false)

    # Check to make sure extra values in the params pass it.
    match, params = routes.send(:check_params_match, {_view: 'blog', _id: '55', _extra: 'some value'}, {_view: 'blog', _id: '55'})
    expect(match).to eq(true)
    expect(params).to eq({_extra: 'some value'})

  end

  it "should match routes" do
    params = Model.new({}, persistor: Persistors::Params)
    params._controller = 'blog'
    params._index = '5'

    routes do
      get '/', _controller: 'index'
      get '/blog', _controller: 'blog'
    end

    path, cleaned_params = @routes.params_to_url(params)
    expect(path).to eq('/blog')
    expect(cleaned_params).to eq({_index: '5'})
  end

  it "should handle routes with bindings in them" do
    params = Model.new({}, persistor: Persistors::Params)

    routes do
      get '/', _controller: 'index'
      get '/blog/{{ _id }}', _controller: 'blog'
    end

    params = @routes.url_to_params('/blog/20')

  end
end
