module Api
  module Rest
    module V1
      class TestController < Api::Rest::V1::BaseController
        def protected
          render json: {
            message: "Authenticated successfully",
            user: {
              id: current_user.id,
              username: current_user.username
            }
          }, status: :ok
        end
      end
    end
  end
end
