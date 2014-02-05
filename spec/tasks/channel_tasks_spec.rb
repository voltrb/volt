# if RUBY_PLATFORM != 'opal'
#   describe "ChannelTasks" do
#     before do
#       load File.join(File.dirname(__FILE__), "../../app/volt/tasks/channel_tasks.rb")
#     end
#     
#     after do
#       Object.send(:remove_const, :ChannelTasks)
#     end
#     
#     it "should let channels be added and removed" do
#       connection = double('socket connection')
#       
#       expect(connection).to receive(:send_message).with('message')
#       
#       @channel_task = ChannelTasks.new(connection)
#       @channel_task.add_listener('channel1', {})
#       
#       ChannelTasks.send_message_to_channel('channel1', 'message')
#     end
#     
#     it "shouldn't send to channels that aren't listening" do
#       connection1 = double('socket connection1')
#       connection2 = double('socket connection2')
#       
#       expect(connection1).to receive(:send_message).with('message for 1')
#       expect(connection1).to_not receive(:send_message).with('message for 2')
#       
#       expect(connection2).to_not receive(:send_message).with('message for 1')
#       expect(connection2).to receive(:send_message).with('message for 2')
#       
#       @channel_task = ChannelTasks.new(connection1)
#       @channel_task.add_listener('channel1')
# 
#       @channel_task = ChannelTasks.new(connection2)
#       @channel_task.add_listener('channel2')
#       
#       ChannelTasks.send_message_to_channel('channel1', 'message for 1')
#       ChannelTasks.send_message_to_channel('channel2', 'message for 2')
#     end
#     
#     it "should remove channels" do
#       connection = double('socket connection')
#       
#       expect(connection).to_not receive(:send_message).with('message for channel1')
#       expect(connection).to receive(:send_message).with('message for channel2')
#       
#       @channel_task = ChannelTasks.new(connection)
#       @channel_task.add_listener('channel1')
#       @channel_task.add_listener('channel2')
#       
#       ChannelTasks.new(connection).remove_listener('channel1')
#       
#       ChannelTasks.send_message_to_channel('channel1', 'message for channel1')
#       ChannelTasks.send_message_to_channel('channel2', 'message for channel2')
#     end
#     
#     it "should remove all when the socket is closed" do
#       connection = double('socket connection')
#       
#       expect(connection).to_not receive(:send_message).with('message for channel1')
#       expect(connection).to_not receive(:send_message).with('message for channel2')
#       
#       @channel_task = ChannelTasks.new(connection)
#       @channel_task.add_listener('channel1')
#       @channel_task.add_listener('channel2')
#       
#       ChannelTasks.new(connection).close!
#       
#       ChannelTasks.send_message_to_channel('channel1', 'message for channel1')
#       ChannelTasks.send_message_to_channel('channel2', 'message for channel2')      
#     end
#   end
# end