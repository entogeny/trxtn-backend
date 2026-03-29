module Auth
  module AccessTokens
    class EncodeService < ApplicationService

      ACCESS_TOKEN_TTL = 1.hour

      def initialize(input = {})
        super
      end

      def call
        super do
          encode_token
        end
      end

      private

      def encode_token
        payload = input[:payload].merge(exp: ACCESS_TOKEN_TTL.from_now.to_i)
        self.output = { token: JWT.encode(payload, secret, "HS256") }
      end

      def secret
        @secret ||= Rails.application.credentials.jwt_secret_key!
      end

    end
  end
end
