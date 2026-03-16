class ApplicationController < ActionController::API
  before_action :authenticate_user!

  private

  def authenticate_user!
    token = bearer_token
    return render_unauthorized("Missing token") if token.blank?

    service = Auth::AccessTokens::DecodeService.new(token: token)
    if service.call
      @current_user_id = service.output[:payload][:sub]
    else
      render_unauthorized(service.errors.first[:message])
    end
  end

  def current_user
    @current_user ||= User.find(@current_user_id)
  end

  def bearer_token
    header = request.headers["Authorization"]
    header&.split(" ")&.last
  end

  def render_unauthorized(message = "Unauthorized")
    render json: { error: message }, status: :unauthorized
  end
end
