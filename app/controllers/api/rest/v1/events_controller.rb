module Api
  module Rest
    module V1
      class EventsController < BaseController

        include Concerns::Serializable

        skip_before_action :authenticate_user!, only: [ :index, :show ]

        def index
          authorize Event, :index?

          service = Events::IndexService.new
          if service.call
            records = service.output[:records]

            render_serialized_json(EventSerializer, records, {
              view: serialization_params[:view]
            }, status: :ok)
          else
            render_errors_json(service.errors, status: :internal_server_error)
          end
        end

        def show
          service = Events::FindService.new(identifier: params[:id])

          if service.call
            event = service.output[:record]
            authorize event, :show?

            render_serialized_json(EventSerializer, event, {
              view: serialization_params[:view]
            }, status: :ok)
          else
            skip_authorization
            render_errors_json(service.errors, status: :not_found)
          end
        end

      end
    end
  end
end
