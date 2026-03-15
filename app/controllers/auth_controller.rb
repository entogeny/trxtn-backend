class AuthController < ApplicationController
  skip_before_action :authenticate_user!

  def signup
    user = User.new(username: params[:username], password: params[:password],
                    password_confirmation: params[:password_confirmation])

    if user.save
      render json: token_pair(user), status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    user = User.find_by("LOWER(username) = ?", params[:username]&.downcase)

    if user&.authenticate(params[:password])
      render json: token_pair(user), status: :ok
    else
      render json: { error: "Invalid username or password" }, status: :unauthorized
    end
  end

  def refresh
    result = Auth::RefreshTokens::RotateService.call(params[:refresh_token])
    render json: result, status: :ok
  rescue Auth::Errors::TokenNotFound, Auth::Errors::TokenRevoked, Auth::Errors::TokenExpired
    render json: { error: "Invalid or expired refresh token" }, status: :unauthorized
  end

  def logout
    Auth::RefreshTokens::RevokeService.call(params[:refresh_token])
    head :no_content
  rescue Auth::Errors::TokenNotFound, Auth::Errors::TokenRevoked
    render json: { error: "Invalid refresh token" }, status: :unauthorized
  end

  private

  def token_pair(user)
    access_token = Auth::AccessTokens::EncodeService.call({ sub: user.id })
    refresh_token = Auth::RefreshTokens::IssueService.call(user)
    { access_token: access_token, refresh_token: refresh_token }
  end
end
