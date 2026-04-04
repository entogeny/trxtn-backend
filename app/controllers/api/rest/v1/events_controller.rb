module Api
  module Rest
    module V1
      class EventsController < BaseController

        skip_before_action :authenticate_user!, only: [ :index ]

        def index
          service = Events::IndexService.new
          if service.call
            render json: EventSerializer.render(service.output[:records], view: :standard), status: :ok
          else
            render json: { errors: service.errors }, status: :internal_server_error
          end
        end

      end
    end
  end
end
