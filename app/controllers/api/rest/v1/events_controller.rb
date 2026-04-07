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

        def create
          authorize Event, :create?

          service = Events::CreateService.new(
            current_user: current_user,
            record_data: {
              description: event_params[:description],
              end_at:      event_params[:end_at],
              name:        event_params[:name],
              start_at:    event_params[:start_at]
            }
          )

          if service.call
            event = service.output[:record]
            render_serialized_json(EventSerializer, event, {
              view: serialization_params[:view]
            }, status: :created)
          else
            render_errors_json(service.errors, status: :unprocessable_content)
          end
        end

        private

        def event_params
          params.require(:event).permit(:description, :end_at, :name, :start_at)
        end

      end
    end
  end
end
