module Auth
  module AccessTokens
    class DecodeService < ApplicationService
      def initialize(input = {})
        super
      end

      def call
        super do
          decode_token
        end
      end

      private

      def decode_token
        decoded = JWT.decode(input[:token], secret, true, algorithm: "HS256")
        self.output = { payload: decoded.first.with_indifferent_access }
      rescue JWT::ExpiredSignature
        add_error("Token has expired")
      rescue JWT::DecodeError
        add_error("Invalid token")
      end

      def secret
        @secret ||= Rails.application.credentials.jwt_secret_key!
      end
    end
  end
end
