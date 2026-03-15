module Auth
  module AccessTokens
    class EncodeService
      ACCESS_TOKEN_TTL = 1.hour

      def self.call(payload)
        payload = payload.merge(exp: ACCESS_TOKEN_TTL.from_now.to_i)
        JWT.encode(payload, secret, "HS256")
      end

      def self.secret
        Rails.application.credentials.jwt_secret_key!
      end
      private_class_method :secret
    end
  end
end
