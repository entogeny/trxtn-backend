module Auth
  class SignupService < ApplicationService
    def initialize(input = {})
      super
    end

    def call
      super do
        ActiveRecord::Base.transaction do
          create_user
          issue_token_pair
        end
      end
    end

    private

    def create_user
      raise ServiceError.new(users_create_service.errors.first[:message]) unless users_create_service.call
    end

    def issue_token_pair
      raise ServiceError.new(token_pair_service.errors.first[:message]) unless token_pair_service.call

      self.output = token_pair_service.output
    end

    def users_create_service
      @users_create_service ||= Users::CreateService.new(
        username: input[:username],
        password: input[:password],
        password_confirmation: input[:password_confirmation]
      )
    end

    def token_pair_service
      @token_pair_service ||= TokenPairService.new(user: users_create_service.output[:user])
    end
  end
end
