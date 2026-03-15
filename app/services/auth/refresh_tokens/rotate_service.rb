module Auth
  module RefreshTokens
    class RotateService
      def self.call(raw_token)
        token_digest = Digest::SHA256.hexdigest(raw_token)
        record = RefreshToken.find_by(token_digest: token_digest)

        raise Auth::Errors::TokenNotFound if record.nil?
        raise Auth::Errors::TokenRevoked if record.revoked_at.present?
        raise Auth::Errors::TokenExpired if record.expires_at <= Time.current

        ActiveRecord::Base.transaction do
          record.update!(revoked_at: Time.current)
          new_raw_token = Auth::RefreshTokens::IssueService.call(record.user)
          access_token = Auth::AccessTokens::EncodeService.call({ sub: record.user.id })

          { access_token: access_token, refresh_token: new_raw_token }
        end
      end
    end
  end
end
