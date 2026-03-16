module Api
  module Rest
    module V1
      class AuthController < Api::Rest::V1::BaseController
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

        private

        def token_pair(user)
          encode_service = Auth::AccessTokens::EncodeService.new(payload: { sub: user.id })
          encode_service.call

          issue_service = Auth::RefreshTokens::IssueService.new(user: user)
          issue_service.call

          { access_token: encode_service.output[:token], refresh_token: issue_service.output[:raw_token] }
        end
      end
    end
  end
end
