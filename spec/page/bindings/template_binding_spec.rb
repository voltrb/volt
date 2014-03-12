require 'spec_helper'
require 'volt/page/bindings/template_binding'

# Setup page stub

class Page
  attr_accessor :templates
end


describe TemplateBinding do
  before do
    @page = double('page')
    expect(@page).to receive(:templates).at_least(1).times.and_return { @templates }

    # TODO: We should decouple things so we don't need to allocate
    @template_binding = TemplateBinding.allocate
    @template_binding.instance_variable_set('@page', @page)
    @template_binding.setup_path('home/index/index')
  end

  def set_template(templates)
    @page.instance_variable_set('@templates', templates)
  end

  after do
    $page = nil
  end

  it "should lookup nested controller action" do
    @templates = {
      'home/index/blog/nav' => '',
      'home/comments/new/body' => '',
    }

    result = @template_binding.path_for_template('comments/new').last
    expect(result).to eq(['home', 'comments_controller', 'new'])
  end

  it "it should not look in the local component/controller for a specified controller/action" do
    @templates = {
      'home/comments/new/body' => ''
    }

    path, result = @template_binding.path_for_template('comments/new')
    expect(path).to eq('home/comments/new/body')
    expect(result).to eq(['home', 'comments_controller', 'new'])
  end


  it "should handle a tripple lookup" do
    @templates = {
      'home/comments/new/errors' => '',
      'comments/new/errors/body' => ''
    }

    path, result = @template_binding.path_for_template('comments/new/errors')
    expect(path).to eq('home/comments/new/errors')
    expect(result).to eq(nil)
  end

  it "should handle a tripple lookup to controllers" do
    @templates = {
      'comments/new/errors/body' => ''
    }

    path, result = @template_binding.path_for_template('comments/new/errors')
    expect(path).to eq('comments/new/errors/body')
    expect(result).to eq(['comments', 'new_controller', 'errors'])
  end


  it "should find a matching component" do
    @templates = {
      'comments/new/index/body' => ''
    }

    path, result = @template_binding.path_for_template('comments/new')
    expect(path).to eq('comments/new/index/body')
    expect(result).to eq(['comments', 'new_controller', 'index'])
  end

  it "should lookup sub-templates within its own file" do
    @templates = {
      'home/index/blog/nav' => '',
      'home/index/index/nav' => '',
    }

    expect(@template_binding.path_for_template('nav').first).to eq('home/index/index/nav')
  end

  it "should lookup sub-templates within another local view" do
    @templates = {
      'home/index/blog/nav' => '',
      'home/index/index/nav' => '',
    }

    expect(@template_binding.path_for_template('blog/nav').first).to eq('home/index/blog/nav')
  end

  it "should lookup in another view" do
    @templates = {
      'home/index/nav/body' => '',
    }

    expect(@template_binding.path_for_template('nav').first).to eq('home/index/nav/body')
  end

  it "should lookup in a controller" do
    @templates = {
      'home/nav/index/body' => ''
    }

    expect(@template_binding.path_for_template('nav').first).to eq('home/nav/index/body')
  end

  it "should lookup in a controller/view" do
    @templates = {
      'home/blog/nav/body' => ''
    }

    expect(@template_binding.path_for_template('blog/nav').first).to eq('home/blog/nav/body')
  end

  it "should lookup in a controller" do
    @templates = {
      'home/nav/index/body' => ''
    }

    expect(@template_binding.path_for_template('nav').first).to eq('home/nav/index/body')
  end

  it "should lookup in a component" do
    @templates = {
      'nav/index/index/body' => ''
    }

    expect(@template_binding.path_for_template('nav').first).to eq('nav/index/index/body')
  end

  it "should lookup in a component/controller/view" do
    @templates = {
      'nav/index/index/body' => '',
      'auth/login/new/body' => ''
    }

    expect(@template_binding.path_for_template('auth/login/new').first).to eq('auth/login/new/body')
  end

  it "should let you force a sub template" do
    @templates = {
      'nav/index/index/title' => '',
      'auth/login/new/title' => ''
    }

    expect(@template_binding.path_for_template('nav', 'title').first).to eq('nav/index/index/title')
  end
end
