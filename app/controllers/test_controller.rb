class TestController < ApplicationController
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
