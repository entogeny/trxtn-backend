module Auth
  module RefreshTokens
    class IssueService < ApplicationService
      REFRESH_TOKEN_TTL = 90.days

      def initialize(input = {})
        super
      end

      def call
        super do
          raw_token = SecureRandom.hex(32)

          input[:user].refresh_tokens.create!(
            token_digest: Digest::SHA256.hexdigest(raw_token),
            expires_at: REFRESH_TOKEN_TTL.from_now
          )

          self.output = { raw_token: raw_token }
        end
      end
    end
  end
end
