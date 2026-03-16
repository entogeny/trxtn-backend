module Auth
  module RefreshTokens
    class RevokeService < ApplicationService
      def initialize(input = {})
        super
      end

      def call
        super do
          find_token_record
          validate_token
          revoke_token
        end
      end

      private

      attr_reader :token_record

      def find_token_record
        @token_record = RefreshToken.find_by(token_digest: Digest::SHA256.hexdigest(input[:raw_token]))
        raise ServiceError.new("Token not found") if token_record.nil?
      end

      def revoke_token
        token_record.update!(revoked_at: Time.current)
      end

      def validate_token
        raise ServiceError.new("Token has already been revoked") if token_record.revoked_at.present?
      end
    end
  end
end
