module Auth
  class LoginService < ApplicationService
    def initialize(input = {})
      super
    end

    def call
      super do
        find_user
        authenticate_user
        issue_token_pair
      end
    end

    private

    attr_reader :user

    def find_user
      @user = User.find_by("LOWER(username) = ?", input[:username]&.downcase)
      # Intentionally vague to prevent username enumeration
      raise ServiceError.new("Invalid username or password") if user.nil?
    end

    def authenticate_user
      # Intentionally vague to prevent username enumeration
      raise ServiceError.new("Invalid username or password") unless user.authenticate(input[:password])
    end

    def issue_token_pair
      raise ServiceError.new(token_pair_service.errors.first[:message]) unless token_pair_service.call

      self.output = token_pair_service.output
    end

    def token_pair_service
      @token_pair_service ||= TokenPairService.new(user: user)
    end
  end
end
