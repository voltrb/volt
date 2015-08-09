module Main
  class EventsController < Volt::ModelController
    reactive_accessor :ran_some_event
    reactive_accessor :ran_other_event

    def trig_some_event
      trigger('some_event', 'yes')
    end

    def some_event(passes_args, event)
      if passes_args == 'yes' && event.is_a?(Volt::JSEvent)
        self.ran_some_event = true
      end
    end

    def trig_other_event
      trigger('other_event', 'yes')
    end

    def other_event(passes_args)
      if passes_args == 'yes'
        self.ran_other_event = true
      end
    end
  end
end