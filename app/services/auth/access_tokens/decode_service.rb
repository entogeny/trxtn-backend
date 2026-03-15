module Auth
  module AccessTokens
    class DecodeService
      def self.call(token)
        decoded = JWT.decode(token, secret, true, algorithm: "HS256")
        decoded.first.with_indifferent_access
      rescue JWT::ExpiredSignature
        raise Auth::Errors::TokenExpired
      rescue JWT::DecodeError
        raise Auth::Errors::TokenInvalid
      end

      def self.secret
        Rails.application.credentials.jwt_secret_key!
      end
      private_class_method :secret
    end
  end
end
