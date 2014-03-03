require 'volt/models'

describe Model do
  it "should create a buffer from an ArrayModel" do
    page = ReactiveValue.new(Model.new)

    page._items = []
    puts page._items.buffer.inspect
  end
end