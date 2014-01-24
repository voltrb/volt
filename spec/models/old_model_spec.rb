# # require 'volt/spec_helper'
# require 'volt/models'
# 
# describe Model do
#   
#   
#   describe "user models" do
#     class User < Model
#       def full_name
#         _first_name + _last_name
#       end
#     end
#   
#     class Info < Model ; end
# 
#     class Todo < Model ; end
#     
#     before do
#       class_models = {
#         ['*', '_user'] => User,
#         ['*', '_info'] => Info,
#         ['*', '_todo'] => Todo
#       }
#       
#       @model = ReactiveValue.new(Model.new({}, nil, 'page', class_models))
#     end
#     
#     it "should be loaded as the correct class" do
#       @model._users << {_name: 'Test'}
#       @model._users[0].cur.is_a?(User).should == true
#     end
#     
#     it "should be loaded in as the correct class for single items" do
#       @model._info._total_users = 5
#       @model._info.cur.is_a?(Info).should == true
#     end
#     
#     it "should load the correct nested class" do
#       @model._todo_lists << {_name: 'Test1', _todos: []}
#       @model._todo_lists[0]._todos << {_label: 'Do something'}
#       @model._todo_lists[0]._todos[0].cur.is_a?(Todo).should == true
#     end
#     
#     it "should assume the default model if used incorrectly" do
#       @model._infos._something = 10
#       @model._infos.cur.is_a?(Info).should == false
#     end
#     
#     it "should keep lookups as children for any looked up value" do
#       @model._users << {_first_name: 'Jim', _last_name: 'Bob'}
#       
#       @model._users.last.cur.is_a?(User).should == true
#       # @model._users.last.full_name.dependents.parents.size.should == 2
#     end
#     
#     it "should call changed on methods that depend on other values" do
#       @model._users << {_first_name: 'Jim', _last_name: 'Bob'}
#       
#       count = 0
#       @model._users.last.full_name.on('changed') { count += 1 }
#       count.should == 0
#       
#       @model._users.last._first_name = 'James'
#       count.should == 1
#     end
#   end
# end