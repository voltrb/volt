require 'volt/models'

describe ReactiveValue do
  it "should concat reactive strings" do
    a = ReactiveValue.new('cool')
    b = ReactiveValue.new('beans')
    
    c = a + b
    expect(c.cur).to eq('coolbeans')
    expect(c.reactive?).to eq(true)
  end
  
  it "should concat reactive and non-reactive" do
    a = ReactiveValue.new('cool')
    b = 'beans'
    
    c = a + b
    expect(c.cur).to eq('coolbeans')
    expect(c.reactive?).to eq(true)    
  end
  
  it "should concat non-reactive and reactive" do
    a = 'cool'
    b = ReactiveValue.new('beans')
    
    c = a + b
    expect(c.cur).to eq('coolbeans')
    expect(c.reactive?).to eq(true)    
  end
  
  if RUBY_PLATFORM != 'opal'
    it "should append reactive to reactive" do
      a = ReactiveValue.new('cool')
      b = ReactiveValue.new('beans')
    
      a << b
      expect(a.cur).to eq('coolbeans')
      expect(a.reactive?).to eq(true)
    end
  end
  
  it "should raise an exception when appending  non-reactive and reactive" do
    a = 'cool'
    b = ReactiveValue.new('beans')
    
    exception_count = 0
    begin
      a << b
    rescue => e
      expect(e.message[/Cannot append a reactive/].cur.true?).to eq(true)
      exception_count += 1
    end
    
    expect(exception_count).to eq(1)
  end

end