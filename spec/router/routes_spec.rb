require 'volt/router/routes'
require 'volt/models'

def routes(&block)
  @routes = Volt::Routes.new
  @routes.define(&block)
end

describe Volt::Routes do
  it 'should setup direct routes' do
    routes do
      client '/', view: 'index'
      client '/page1', view: 'first_page'
      get '/page2', controller: 'page', action: 'show'
    end

    direct_routes = @routes.instance_variable_get(:@direct_routes)
    expect(direct_routes[:client]).to eq('/' => { view: 'index' }, '/page1' => { view: 'first_page' })
    expect(direct_routes[:get]).to eq('/page2' => { controller: 'page', action: 'show' })
  end

  it 'should setup indirect routes' do
    routes do
      client '/blog/{{ id }}/edit', view: 'blog/edit'
      client '/blog/{{ id }}', view: 'blog/show'
      get '/comments/{{ id }}/edit', controller: 'comments', action: 'edit'
      get '/comments/{{ id }}', controller: 'comments', action: 'show'
    end

    indirect_routes = @routes.instance_variable_get(:@indirect_routes)
    expect(indirect_routes[:client]).to eq(
      'blog' => {
        '*' => {
          'edit' => {
            nil => { view: 'blog/edit', id: 1 }
          },
          nil => { view: 'blog/show', id: 1 }
        }
      }
    )

    expect(indirect_routes[:get]).to eq(
      'comments' => {
        '*' => {
          'edit' => {
            nil => { controller: 'comments', action: 'edit', id: 1 }
          },
          nil => { controller: 'comments', action: 'show', id: 1 }
        }
      }
    )
  end

  it 'should setup param matchers' do
    routes do
      client '/blog', view: 'blog'
      client '/blog/{{ id }}', view: 'blog/show'
      client '/blog/{{ id }}/edit', view: 'blog/edit'
      client '/blog/tags/{{ tag }}', view: 'blog/tag'
      client '/login/{{ name }}/user/{{ id }}', view: 'login', action: 'user'
      get '/articles', controller: 'articles', action: 'index'
      get '/articles/{{ id }}', controller: 'articles', action: 'show'
    end

    param_matches = @routes.instance_variable_get(:@param_matches)
    expect(param_matches[:client].map { |v| v[0] }).to eq([
      { view: 'blog' },
      { view: 'blog/show', id: nil },
      { view: 'blog/edit', id: nil },
      { view: 'blog/tag', tag: nil },
      { view: 'login', action: 'user', name: nil, id: nil }
    ])

    expect(param_matches[:get].map { |v| v[0] }).to eq([
      { controller: 'articles', action: 'index' },
      { controller: 'articles', action: 'show', id: nil }
    ])
  end

  it 'should match routes' do
    routes do
      client '/blog', view: 'blog'
      client '/blog/{{ id }}', view: 'blog/show'
      client '/blog/{{ id }}/draft', view: 'blog/draft', action: 'draft'
      client '/blog/{{ id }}/edit', view: 'blog/edit'
      client '/blog/tags/{{ tag }}', view: 'blog/tag'
      client '/login/{{ name }}/user/{{ id }}', view: 'login', action: 'user'
      get '/articles', controller: 'articles', action: 'index'
      get '/articles/{{ id }}', controller: 'articles', action: 'show'
      put '/articles/{{ articles_id }}/comments/{{ id }}', controller: 'comments', action: 'update'
      post '/comments', controller: 'comments', action: 'create'
      put '/people', controller: 'people', action: 'update'
      patch '/people/1', controller: 'people', action: 'update'
      delete '/people/2', controller: 'people', action: 'destroy'
    end

    params = @routes.url_to_params('/blog')
    expect(params).to eq(view: 'blog')

    params = @routes.url_to_params('/blog/55/edit')
    expect(params).to eq(view: 'blog/edit', id: '55')

    params = @routes.url_to_params('/blog/55')
    expect(params).to eq(view: 'blog/show', id: '55')

    params = @routes.url_to_params('/blog/tags/good')
    expect(params).to eq(view: 'blog/tag', tag: 'good')

    params = @routes.url_to_params('/blog/55/draft')
    expect(params).to eq(view: 'blog/draft', id: '55', action: 'draft')

    params = @routes.url_to_params('/login/jim/user/10')
    expect(params).to eq(view: 'login', action: 'user', name: 'jim', id: '10')

    params = @routes.url_to_params('/login/cool')
    expect(params).to eq(false)

    params = @routes.url_to_params(:get, '/articles')
    expect(params).to eq(controller: 'articles', action: 'index')

    params = @routes.url_to_params('get', '/articles')
    expect(params).to eq(controller: 'articles', action: 'index')

    params = @routes.url_to_params(:post, '/articles')
    expect(params).to be_nil

    params = @routes.url_to_params(:post, '/comments')
    expect(params).to eq(controller: 'comments', action: 'create')

    params = @routes.url_to_params(:put, '/people')
    expect(params).to eq(controller: 'people', action: 'update')

    params = @routes.url_to_params(:patch, '/people/1')
    expect(params).to eq(controller: 'people', action: 'update')

    params = @routes.url_to_params(:delete, '/people/2')
    expect(params).to eq(controller: 'people', action: 'destroy')

    params = @routes.url_to_params(:get, '/articles/2')
    expect(params).to eq(controller: 'articles', action: 'show', id: '2')

    params = @routes.url_to_params(:put, '/articles/2/comments/9')
    expect(params).to eq(controller: 'comments', action: 'update', articles_id: '2', id: '9')
  end

  it 'should go from params to url' do
    routes do
      client '/blog', view: 'blog'
      client '/blog/{{ id }}', view: 'blog/show'
      client '/blog/{{ id }}/edit', view: 'blog/edit'
      client '/blog/tags/{{ tag }}', view: 'blog/tag'
      client '/login/{{ name }}/user/{{ id }}', view: 'login', action: 'user'
      get '/articles/{{ id }}', controller: 'articles', action: 'show'
      put '/articles/{{ id }}', controller: 'articles', action: 'update'
    end

    url, params = @routes.params_to_url(view: 'blog/show', id: '55')
    expect(url).to eq('/blog/55')
    expect(params).to eq({})

    url, params = @routes.params_to_url(view: 'blog/edit', id: '100')
    expect(url).to eq('/blog/100/edit')
    expect(params).to eq({})

    url, params = @routes.params_to_url(view: 'blog/edit', id: '100', other: 'should_pass')
    expect(url).to eq('/blog/100/edit')
    expect(params).to eq(other: 'should_pass')

    url, params = @routes.params_to_url(controller: 'articles', action: 'show', method: :get, id: 10)
    expect(url).to eq('/articles/10')
    expect(params).to eq({})

    url, params = @routes.params_to_url(controller: 'articles', action: 'update', method: :put, id: 99, other: 'xyz')
    expect(url).to eq('/articles/99')
    expect(params).to eq(other: 'xyz')

    url, params = @routes.params_to_url({})
    expect(url).to eq(nil)
    expect(params).to eq(nil)
  end

  it 'should test that params match a param matcher' do
    routes = Volt::Routes.new
    match, params = routes.send(:check_params_match, { view: 'blog', id: '55' }, view: 'blog', id: nil)
    expect(match).to eq(true)
    expect(params).to eq(id: '55')

    match, params = routes.send(:check_params_match, { view: 'blog', id: '55' }, view: 'blog', id: '20')
    expect(match).to eq(false)

    match, params = routes.send(:check_params_match, { view: 'blog', name: { _title: 'Mr', name: 'Bob' }, id: '55' }, view: 'blog', id: nil, name: { _title: 'Mr', name: nil })
    expect(match).to eq(true)
    expect(params).to eq(id: '55')

    # Check with an extra value name.name
    match, params = routes.send(:check_params_match, { view: 'blog', name: { _title: 'Mr', name: 'Bob' }, id: '55' }, view: 'blog', id: nil, name: { _title: 'Mr' })
    expect(match).to eq(true)
    expect(params).to eq(id: '55')

    match, params = routes.send(:check_params_match, { view: 'blog', name: { _title: 'Mr', name: 'Bob' }, id: '55' }, view: 'blog', id: nil, name: { _title: 'Phd' })
    expect(match).to eq(false)

    # Check to make sure extra values in the params pass it.
    match, params = routes.send(:check_params_match, { view: 'blog', id: '55', _extra: 'some value' }, view: 'blog', id: '55')
    expect(match).to eq(true)
    expect(params).to eq(_extra: 'some value')

    match, params = routes.send(:check_params_match, { view: 'blog', id: '55' }, view: 'blog', id: '20')
    expect(match).to eq(false)
  end

  it 'should not match params that have no matches at all' do
    routes = Volt::Routes.new
    match, params = routes.send(:check_params_match, { view: '', id: false }, bleep: { volt: 'rocks' })
    expect(match).to eq(false)
  end

  it 'should not match params that have a nil value' do
    routes = Volt::Routes.new
    match, params = routes.send(:check_params_match, { view: 'blog', id: false }, bleep: nil)
    expect(match).to eq(false)
  end

  it 'should match routes' do
    params = Volt::Model.new({}, persistor: Volt::Persistors::Params)
    params._controller = 'blog'
    params._index = '5'

    routes do
      client '/', controller: 'index'
      client '/blog', controller: 'blog'
    end

    path, cleaned_params = @routes.params_to_url(params.to_h)
    expect(path).to eq('/blog')
    expect(cleaned_params.without(:id)).to eq(index: '5')
  end

  it 'should handle routes with bindings in them' do
    params = Volt::Model.new({}, persistor: Volt::Persistors::Params)

    routes do
      client '/', controller: 'index'
      client '/blog/{{ id }}', controller: 'blog'
    end

    params = @routes.url_to_params('/blog/20')
  end

  it 'should setup RESTful routes' do
    routes do
      rest '/api/v1/articles', controller: 'articles'
    end

    params = @routes.url_to_params(:get, '/api/v1/articles')
    expect(params).to eq(controller: 'articles', action: 'index')

    params = @routes.url_to_params(:get, '/api/v1/articles/1')
    expect(params).to eq(controller: 'articles', action: 'show', id: '1')

    params = @routes.url_to_params(:post, '/api/v1/articles')
    expect(params).to eq(controller: 'articles', action: 'create')

    params = @routes.url_to_params(:put, '/api/v1/articles/1')
    expect(params).to eq(controller: 'articles', action: 'update', id: '1')

    params = @routes.url_to_params(:delete, '/api/v1/articles/1')
    expect(params).to eq(controller: 'articles', action: 'destroy', id: '1')
  end

  it 'should only setup desired RESTful routes' do
    routes do
      rest '/api/v1/articles', controller: 'articles', only: [:index, :show]
    end

    params = @routes.url_to_params(:get, '/api/v1/articles')
    expect(params).to eq(controller: 'articles', action: 'index')

    params = @routes.url_to_params(:get, '/api/v1/articles/1')
    expect(params).to eq(controller: 'articles', action: 'show', id: '1')

    expect(@routes.url_to_params(:post, '/api/v1/articles')).to be_nil
    expect(@routes.url_to_params(:put, '/api/v1/articles/1')).to be_nil
    expect(@routes.url_to_params(:delete, '/api/v1/articles/1')).to be_nil

    routes do
      rest '/api/v1/articles', controller: 'articles', only: [:update, :destroy, :create]
    end

    expect(@routes.url_to_params(:get, '/api/v1/articles')).to be_nil
    expect(@routes.url_to_params(:get, '/api/v1/articles/1')).to be_nil

    params = @routes.url_to_params(:post, '/api/v1/articles')
    expect(params).to eq(controller: 'articles', action: 'create')

    params = @routes.url_to_params(:put, '/api/v1/articles/1')
    expect(params).to eq(controller: 'articles', action: 'update', id: '1')

    params = @routes.url_to_params(:delete, '/api/v1/articles/1')
    expect(params).to eq(controller: 'articles', action: 'destroy', id: '1')
  end

  it 'should exclude undesired RESTful routes' do
    routes do
      rest '/api/v1/articles', controller: 'articles', except: [:update, :destroy, :create]
    end

    params = @routes.url_to_params(:get, '/api/v1/articles')
    expect(params).to eq(controller: 'articles', action: 'index')

    params = @routes.url_to_params(:get, '/api/v1/articles/1')
    expect(params).to eq(controller: 'articles', action: 'show', id: '1')

    expect(@routes.url_to_params(:post, '/api/v1/articles')).to be_nil
    expect(@routes.url_to_params(:put, '/api/v1/articles/1')).to be_nil
    expect(@routes.url_to_params(:delete, '/api/v1/articles/1')).to be_nil
  end
end
