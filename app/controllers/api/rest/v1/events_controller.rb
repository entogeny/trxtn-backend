module Api
  module Rest
    module V1
      class EventsController < BaseController

        skip_before_action :authenticate_user!, only: [ :index ]

        def index
          service = Events::IndexService.new
          if service.call
            render json: service.output[:records].map { |event| render_event(event) }
          else
            render json: { errors: service.errors }, status: :internal_server_error
          end
        end

        private

        def render_event(event)
          {
            id:          event.id,
            name:        event.name,
            description: event.description,
            start_at:    event.start_at,
            end_at:      event.end_at,
            created_at:  event.created_at,
            updated_at:  event.updated_at
          }
        end

      end
    end
  end
end
