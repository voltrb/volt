require 'volt/controllers/restfull_base_controller'

module Volt
  # Allow you to create controllers that act as http endpoints
  class SimpleJsonController < RestfullBaseController

    def index
      render json: { collection_name => collection.all.to_a.sync }
    end

    def show
      render json: { model => resource.to_h }
    end

    def create
      collection.append(resource).then do
        # TODO http_controllers should be able to get routes via params
        head :created #, location: params_to_url(:get, component: params._component, controller: params._controller, id: resource.id)
      end.fail do |err|

      end
    end

    def update
      resource.update(resource_params)
      resource.save!.then do
        head :no_content
      end.fail do
      
      end
    end

    def destroy
      resource.destroy.then do
        head :no_content
      end.fail do |err|

      end
    end
    
  end
end
