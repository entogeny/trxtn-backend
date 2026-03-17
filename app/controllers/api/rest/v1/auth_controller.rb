module Api
  module Rest
    module V1
      class AuthController < Api::Rest::V1::BaseController
        skip_before_action :authenticate_user!

        def signup
          user = User.new(username: params[:username], password: params[:password],
                          password_confirmation: params[:password_confirmation])

          if user.save
            service = Auth::TokenPairService.new(user: user)
            service.call
            render json: service.output, status: :created
          else
            render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def login
          service = Auth::LoginService.new(username: params[:username], password: params[:password])
          if service.call
            render json: service.output, status: :ok
          else
            render json: { errors: service.errors }, status: :unauthorized
          end
        end

        def refresh
          service = Auth::RefreshTokens::RotateService.new(raw_token: params[:refresh_token])
          if service.call
            render json: service.output, status: :ok
          else
            render json: { errors: service.errors }, status: :unauthorized
          end
        end

        def logout
          service = Auth::RefreshTokens::RevokeService.new(raw_token: params[:refresh_token])
          if service.call
            head :no_content
          else
            render json: { errors: service.errors }, status: :unauthorized
          end
        end
      end
    end
  end
end
