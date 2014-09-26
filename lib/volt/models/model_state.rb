# All models have a state that has to do with it being loaded, in process of
# being loaded, or not yet loading.
module ModelState

  def state
    if @persistor && @persistor.respond_to?(:state)
      @persistor.state
    else
      @state || :loaded
    end
  end

  def change_state_to(state)
    @state = state
  end

  def loaded?
    self.state == :loaded
  end


end
