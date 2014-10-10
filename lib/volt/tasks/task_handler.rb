class TaskHandler
  def initialize(channel=nil, dispatcher=nil)
    @channel = channel
    @dispatcher = dispatcher
  end

  def self.inherited(subclass)
    @subclasses ||= []
    @subclasses << subclass
  end

  def self.known_handlers
    @subclasses ||= []
  end
end