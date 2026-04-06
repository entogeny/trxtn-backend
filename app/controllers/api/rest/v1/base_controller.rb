module Api
  module Rest
    module V1
      class BaseController < Api::Rest::BaseController

        # Included here so all controllers inherit consistent JSON error formatting
        # and rescue_from handlers (RecordNotFound, Pundit::NotAuthorizedError)
        # without needing to opt in per-controller.
        include Concerns::Errorable

        after_action :verify_authorized

      end
    end
  end
end
