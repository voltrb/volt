require 'volt/controllers/http_controller'

module Volt
  # Allow you to create controllers that act as http endpoints
  class RestfullBaseController < HttpController

    before_action :setup_model
    before_action :setup_new_resource, only: [:create]
    before_action :setup_buffered_resource, only: [:update]
    before_action :setup_resource, only: [:show, :destroy]

    private

    attr_reader :model, :resource

    def self.model(model = :not_set)
      if model == :not_set
        @model
      else
        @model = model.to_sym
      end
    end

    def collection_name
      model.pluralize
    end

    def collection
      store.send(collection_name)
    end

    def resource_params
      params.send(:"_#{model}")
    end

    def setup_model
      @model = self.class.model || params._model.try(:to_sym)
      unless @model
        render text: "No model given", status: :internal_server_error
        stop_chain
      end
    end

    def setup_new_resource
      @resource = collection.new(resource_params)
    end

    def setup_resource
      @resource = collection.where(id: params.id).first.sync
      unless @resource
        head :not_found
        stop_chain
      end
    end

    def setup_buffered_resource
      setup_resource
      @resource = @resource.buffer
    end

  end
end

