module Auth
  module RefreshTokens
    class RotateService < ApplicationService
      def initialize(input = {})
        super
      end

      def call
        super do
          find_token_record
          validate_token
          rotate_token_pair
        end
      end

      private

      attr_reader :token_record

      def find_token_record
        @token_record = RefreshToken.find_by(token_digest: Digest::SHA256.hexdigest(input[:raw_token]))
        raise ServiceError.new("Token not found") if token_record.nil?
      end

      def rotate_token_pair
        ActiveRecord::Base.transaction do
          token_record.update!(revoked_at: Time.current)

          issue_service = IssueService.new(user: token_record.user)
          raise ServiceError.new(issue_service.errors.first[:message]) if !issue_service.call

          encode_service = AccessTokens::EncodeService.new(payload: { sub: token_record.user.id })
          raise ServiceError.new(encode_service.errors.first[:message]) if !encode_service.call

          self.output = {
            access_token: encode_service.output[:token],
            refresh_token: issue_service.output[:raw_token]
          }
        end
      end

      def validate_token
        raise ServiceError.new("Token has been revoked") if token_record.revoked_at.present?
        raise ServiceError.new("Token has expired") if token_record.expires_at <= Time.current
      end
    end
  end
end
