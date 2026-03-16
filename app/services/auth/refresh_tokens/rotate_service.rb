module Auth
  module RefreshTokens
    class RotateService < ApplicationService
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
            raise ServiceError.new("Token has been revoked")
          end

          if record.expires_at <= Time.current
            raise ServiceError.new("Token has expired")
          end

          ActiveRecord::Base.transaction do
            record.update!(revoked_at: Time.current)

            issue_service = IssueService.new(user: record.user)
            raise ServiceError.new(issue_service.errors.first[:message]) unless issue_service.call

            encode_service = AccessTokens::EncodeService.new(payload: { sub: record.user.id })
            raise ServiceError.new(encode_service.errors.first[:message]) unless encode_service.call

            self.output = {
              access_token: encode_service.output[:token],
              refresh_token: issue_service.output[:raw_token]
            }
          end
        end
      end
    end
  end
end
