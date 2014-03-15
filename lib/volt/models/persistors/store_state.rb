# StoreState provides method for a store to track its loading state.
module StoreState

  # Called when a collection loads
  def loaded(initial_state=nil)
    change_state_to(initial_state || :not_loaded)
  end

  def state
    @state
  end

  # Called from the QueryListener when the data is loaded
  def change_state_to(new_state)
    @state = new_state

    # Trigger changed on the 'state' method
    @model.trigger_for_methods!('changed', :state, :loaded?)

    if @state == :loaded && @fetch_promises
      # Trigger each waiting fetch
      @fetch_promises.compact.each {|fp| fp.resolve(@model) }
      @fetch_promises = nil
    end
  end

end
