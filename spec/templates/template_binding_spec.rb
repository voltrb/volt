require 'volt/page/bindings/template_binding'

# Setup page stub

class Page
  attr_accessor :templates
end


describe TemplateBinding do
  before do
    $page = Page.new
    
    # TODO: We should decouple things so we don't need to allocate
    @template_binding = TemplateBinding.allocate
    @template_binding.setup_path('home/index/index')
  end
  
  after do
    $page = nil
  end
  
  it "should lookup sub-templates within its own file" do
    $page.templates = {
      'home/index/blog/nav' => '',
      'home/index/index/nav' => '',
    }
    
    expect(@template_binding.path_for_template('nav').first).to eq('home/index/index/nav')
  end
  
  it "should lookup sub-templates within another local view" do
    $page.templates = {
      'home/index/blog/nav' => '',
      'home/index/index/nav' => '',
    }
    
    expect(@template_binding.path_for_template('blog/nav').first).to eq('home/index/blog/nav')
  end
  
  it "should lookup in another view" do
    $page.templates = {
      'home/index/nav/body' => '',
    }
    
    expect(@template_binding.path_for_template('nav').first).to eq('home/index/nav/body')    
  end
  
  it "should lookup in a controller" do
    $page.templates = {
      'home/nav/index/body' => ''
    }
    
    expect(@template_binding.path_for_template('nav').first).to eq('home/nav/index/body')    
  end
  
  it "should lookup in a controller/view" do
    $page.templates = {
      'home/blog/nav/body' => ''
    }
    
    expect(@template_binding.path_for_template('blog/nav').first).to eq('home/blog/nav/body')        
  end
  
  it "should lookup in a controller" do
    $page.templates = {
      'home/nav/index/body' => ''
    }
    
    expect(@template_binding.path_for_template('nav').first).to eq('home/nav/index/body')            
  end
  
  it "should lookup in a component" do
    $page.templates = {
      'nav/index/index/body' => ''
    }
    
    expect(@template_binding.path_for_template('nav').first).to eq('nav/index/index/body')                
  end
  
  it "should lookup in a component/controller/view" do
    $page.templates = {
      'nav/index/index/body' => '',
      'auth/login/new/body' => ''
    }
    
    expect(@template_binding.path_for_template('auth/login/new').first).to eq('auth/login/new/body')
  end
  
  it "should let you force a sub template" do
    $page.templates = {
      'nav/index/index/title' => '',
      'auth/login/new/title' => ''
    }
    
    expect(@template_binding.path_for_template('nav', 'title').first).to eq('nav/index/index/title')    
  end
end