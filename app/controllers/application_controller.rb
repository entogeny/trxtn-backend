class ApplicationController < ActionController::API
  before_action :authenticate_user!

  private

  def authenticate_user!
    token = bearer_token
    return render_unauthorized("Missing token") if token.blank?

    payload = Auth::AccessTokens::DecodeService.call(token)
    @current_user_id = payload[:sub]
  rescue Auth::Errors::TokenExpired
    render_unauthorized("Token has expired")
  rescue Auth::Errors::TokenInvalid
    render_unauthorized("Invalid token")
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
