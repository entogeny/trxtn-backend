module Api
  module Rest
    module V1
      class EventsController < BaseController

        include Concerns::Errorable
        include Concerns::Serializable

        skip_before_action :authenticate_user!, only: [ :index ]

        def index
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

      end
    end
  end
end
