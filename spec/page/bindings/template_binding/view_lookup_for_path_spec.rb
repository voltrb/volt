require 'spec_helper'
require 'volt/page/bindings/template_binding'

# Setup page stub

class Volt::Page
  attr_accessor :templates
end

describe Volt::TemplateBinding do
  before do
    @page = double('volt/page')
    expect(@page).to receive(:templates).at_least(1).times { @templates }

    # TODO: We should decouple things so we don't need to allocate
    @view_lookup = Volt::ViewLookupForPath.new(@page, 'main/main/main')
  end

  def set_template(templates)
    @page.instance_variable_set('@templates', templates)
  end

  it 'should lookup nested controller action' do
    @templates = {
      'main/main/blog/nav' => '',
      'main/comments/new/body' => ''
    }

    result = @view_lookup.path_for_template('comments/new').last
    expect(result).to eq(%w(main comments_controller new))
  end

  it 'it should not look in the local component/controller for a specified controller/action' do
    @templates = {
      'main/comments/new/body' => ''
    }

    path, result = @view_lookup.path_for_template('comments/new')
    expect(path).to eq('main/comments/new/body')
    expect(result).to eq(%w(main comments_controller new))
  end

  it 'should handle a tripple lookup' do
    @templates = {
      'main/comments/new/errors' => '',
      'comments/new/errors/body' => ''
    }

    path, result = @view_lookup.path_for_template('comments/new/errors')
    expect(path).to eq('main/comments/new/errors')
    expect(result).to eq(%w(main comments_controller errors))
  end

  it 'should handle a tripple lookup to controllers' do
    @templates = {
      'comments/new/errors/body' => ''
    }

    path, result = @view_lookup.path_for_template('comments/new/errors')
    expect(path).to eq('comments/new/errors/body')
    expect(result).to eq(%w(comments new_controller errors))
  end

  it 'should find a matching component' do
    @templates = {
      'comments/new/index/body' => ''
    }

    path, result = @view_lookup.path_for_template('comments/new')
    expect(path).to eq('comments/new/index/body')
    expect(result).to eq(%w(comments new_controller index))
  end

  it 'should lookup sub-templates within its own file' do
    @templates = {
      'main/main/blog/nav' => '',
      'main/main/main/nav' => ''
    }

    expect(@view_lookup.path_for_template('nav').first).to eq('main/main/main/nav')
  end

  it 'should lookup sub-templates within another local view' do
    @templates = {
      'main/main/blog/nav' => '',
      'main/main/main/nav' => ''
    }

    expect(@view_lookup.path_for_template('blog/nav').first).to eq('main/main/blog/nav')
  end

  it 'should lookup in another view' do
    @templates = {
      'main/main/nav/body' => ''
    }

    expect(@view_lookup.path_for_template('nav').first).to eq('main/main/nav/body')
  end

  it 'should lookup in a controller' do
    @templates = {
      'main/nav/index/body' => ''
    }

    expect(@view_lookup.path_for_template('nav').first).to eq('main/nav/index/body')
  end

  it 'should lookup in a controller/view' do
    @templates = {
      'main/blog/nav/body' => ''
    }

    expect(@view_lookup.path_for_template('blog/nav').first).to eq('main/blog/nav/body')
  end

  it 'should lookup in a controller' do
    @templates = {
      'main/nav/index/body' => ''
    }

    expect(@view_lookup.path_for_template('nav').first).to eq('main/nav/index/body')
  end

  it 'should lookup in a component' do
    @templates = {
      'nav/main/index/body' => ''
    }

    expect(@view_lookup.path_for_template('nav').first).to eq('nav/main/index/body')
  end

  it 'should lookup in a component/controller/view' do
    @templates = {
      'nav/main/main/body' => '',
      'auth/login/new/body' => ''
    }

    expect(@view_lookup.path_for_template('auth/login/new').first).to eq('auth/login/new/body')
  end

  it 'should let you force a sub template' do
    @templates = {
      'nav/main/index/title' => '',
      'auth/login/new/title' => ''
    }

    expect(@view_lookup.path_for_template('nav', 'title').first).to eq('nav/main/index/title')
  end
end
