module Api
  module Rest
    module V1
      class AuthController < Api::Rest::V1::BaseController
        skip_before_action :authenticate_user!

        def signup
          users_create_service = Users::CreateService.new(
            username: params[:username],
            password: params[:password],
            password_confirmation: params[:password_confirmation]
          )

          if users_create_service.call
            token_service = Auth::TokenPairService.new(user: users_create_service.output[:user])
            token_service.call
            render json: token_service.output, status: :created
          else
            render json: { errors: users_create_service.errors }, status: :unprocessable_entity
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
