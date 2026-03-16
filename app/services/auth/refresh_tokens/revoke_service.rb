module Auth
  module RefreshTokens
    class RevokeService < ApplicationService
      def initialize(input = {})
        super
      end

      def call
        super do
          token_digest = Digest::SHA256.hexdigest(input[:raw_token])
          record = RefreshToken.find_by(token_digest: token_digest)

          if record.nil?
            raise ServiceError.new("Token not found")
          end

          if record.revoked_at.present?
            raise ServiceError.new("Token has already been revoked")
          end

          record.update!(revoked_at: Time.current)
        end
      end
    end
  end
end
