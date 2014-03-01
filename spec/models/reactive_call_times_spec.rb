# require 'volt/models'
#
# class Test1 < Model
#   def test
#     puts "YEP"
#
#     {:yes => true}
#   end
# end
#
# describe ReactiveValue do
#   it "should not trigger a model method multiple times" do
#     a = ReactiveValue.new(Test1.new)
#
#     test = a.test
#
#     test.on('changed') { puts "CH" }
#     a._name.on('changed') { puts "NAME CH" }
#
#     puts "--------"
#     a._name = 'ok'
#
#
#
#
#     # a.test
#   end
# end