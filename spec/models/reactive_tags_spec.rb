require 'volt/models'

class TestCustomClass
  include ReactiveTags

  tag_method(:cool) do
    destructive!
  end
end

class TestSubClass < TestCustomClass

end

class TestInherit < TestCustomClass
  tag_method(:cool) do
    pass_reactive!
  end
end

describe ReactiveTags do
  it "should tag correctly" do
    expect(TestCustomClass.new.reactive_method_tag(:cool, :destructive)).to eq(true)
  end

  it "should include tags in a subclass" do
    expect(TestSubClass.new.reactive_method_tag(:cool, :destructive)).to eq(true)
    expect(TestSubClass.new.reactive_method_tag(:cool, :pass_reactive)).to eq(nil)
  end

  it "should inherit" do
    expect(TestInherit.new.reactive_method_tag(:cool, :destructive)).to eq(true)
    expect(TestInherit.new.reactive_method_tag(:cool, :pass_reactive)).to eq(true)
  end
end
