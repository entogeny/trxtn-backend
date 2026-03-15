module Auth
  module RefreshTokens
    class RevokeService
      def self.call(raw_token)
        token_digest = Digest::SHA256.hexdigest(raw_token)
        record = RefreshToken.find_by(token_digest: token_digest)

        raise Auth::Errors::TokenNotFound if record.nil?
        raise Auth::Errors::TokenRevoked if record.revoked_at.present?

        record.update!(revoked_at: Time.current)
      end
    end
  end
end
