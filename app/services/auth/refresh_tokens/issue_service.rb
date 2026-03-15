module Auth
  module RefreshTokens
    class IssueService
      REFRESH_TOKEN_TTL = 90.days

      def self.call(user)
        raw_token = SecureRandom.hex(32)
        token_digest = Digest::SHA256.hexdigest(raw_token)

        user.refresh_tokens.create!(
          token_digest: token_digest,
          expires_at: REFRESH_TOKEN_TTL.from_now
        )

        raw_token
      end
    end
  end
end
