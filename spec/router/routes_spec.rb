require 'volt/router/routes'
require 'volt/models'

def routes(&block)
  @routes = Volt::Routes.new
  @routes.define(&block)
end

describe Volt::Routes do
  it 'should setup direct routes' do
    routes do
      get '/', view: 'index'
      get '/page1', view: 'first_page'
    end

    direct_routes = @routes.instance_variable_get(:@direct_routes)
    expect(direct_routes).to eq('/' => { view: 'index' }, '/page1' => { view: 'first_page' })
  end

  it 'should setup indirect routes' do
    routes do
      get '/blog/{{ id }}/edit', view: 'blog/edit'
      get '/blog/{{ id }}', view: 'blog/show'
    end

    indirect_routes = @routes.instance_variable_get(:@indirect_routes)
    expect(indirect_routes).to eq(
      'blog' => {
        '*' => {
          'edit' => {
            nil => { view: 'blog/edit', id: 1 }
          },
          nil => { view: 'blog/show', id: 1 }
        }
      }
    )
  end

  it 'should match routes' do
    routes do
      get '/blog', view: 'blog'
      get '/blog/{{ id }}', view: 'blog/show'
      get '/blog/{{ id }}/draft', view: 'blog/draft', action: 'draft'
      get '/blog/{{ id }}/edit', view: 'blog/edit'
      get '/blog/tags/{{ _tag }}', view: 'blog/tag'
      get '/login/{{ name }}/user/{{ id }}', view: 'login', action: 'user'
    end

    params = @routes.url_to_params('/blog')
    expect(params).to eq(view: 'blog')

    params = @routes.url_to_params('/blog/55/edit')
    expect(params).to eq(view: 'blog/edit', id: '55')

    params = @routes.url_to_params('/blog/55')
    expect(params).to eq(view: 'blog/show', id: '55')

    params = @routes.url_to_params('/blog/tags/good')
    expect(params).to eq(view: 'blog/tag', _tag: 'good')

    params = @routes.url_to_params('/blog/55/draft')
    expect(params).to eq(view: 'blog/draft', id: '55', action: 'draft')

    params = @routes.url_to_params('/login/jim/user/10')
    expect(params).to eq(view: 'login', action: 'user', name: 'jim', id: '10')

    params = @routes.url_to_params('/login/cool')
    expect(params).to eq(false)
  end

  it 'should setup param matchers' do
    routes do
      get '/blog', view: 'blog'
      get '/blog/{{ id }}', view: 'blog/show'
      get '/blog/{{ id }}/edit', view: 'blog/edit'
      get '/blog/tags/{{ _tag }}', view: 'blog/tag'
      get '/login/{{ name }}/user/{{ id }}', view: 'login', action: 'user'
    end

    param_matches = @routes.instance_variable_get(:@param_matches)
    expect(param_matches.map { |v| v[0] }).to eq([
      { view: 'blog' },
      { view: 'blog/show', id: nil },
      { view: 'blog/edit', id: nil },
      { view: 'blog/tag', _tag: nil },
      { view: 'login', action: 'user', name: nil, id: nil }
    ])
  end

  it 'should go from params to url' do
    routes do
      get '/blog', view: 'blog'
      get '/blog/{{ id }}', view: 'blog/show'
      get '/blog/{{ id }}/edit', view: 'blog/edit'
      get '/blog/tags/{{ _tag }}', view: 'blog/tag'
      get '/login/{{ name }}/user/{{ id }}', view: 'login', action: 'user'
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
  end

  it 'should match routes' do
    params = Volt::Model.new({}, persistor: Volt::Persistors::Params)
    params._controller = 'blog'
    params._index = '5'

    routes do
      get '/', controller: 'index'
      get '/blog', controller: 'blog'
    end

    path, cleaned_params = @routes.params_to_url(params.to_h)
    expect(path).to eq('/blog')
    expect(cleaned_params).to eq(index: '5')
  end

  it 'should handle routes with bindings in them' do
    params = Volt::Model.new({}, persistor: Volt::Persistors::Params)

    routes do
      get '/', controller: 'index'
      get '/blog/{{ id }}', controller: 'blog'
    end

    params = @routes.url_to_params('/blog/20')
  end
end
