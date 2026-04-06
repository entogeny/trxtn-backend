module Api
  module Rest
    module V1
      module Concerns
        module Errorable
          extend ActiveSupport::Concern

          DEFAULT_STATUS = :internal_server_error

          included do
            rescue_from(ActiveRecord::RecordNotFound) { |exception| handle_exception(exception, status: :not_found) }
            rescue_from(Pundit::NotAuthorizedError) { |exception| handle_exception(exception, status: :forbidden) }
          end

          def render_errors_json(errors = [], status: DEFAULT_STATUS)
            render json: {
              errors: errors
            }, status: status
          end

          protected

          def handle_exception(exception, status: DEFAULT_STATUS)
            errors = [ exception.message ]
            render_errors_json(errors, status: status)
          end
        end
      end
    end
  end
end
