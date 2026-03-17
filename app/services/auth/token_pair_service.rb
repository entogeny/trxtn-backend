module Auth
  class TokenPairService < ApplicationService
    def initialize(input = {})
      super
    end

    def call
      super do
        encode_token
        issue_token
        compose_token_pair
      end
    end

    private

    def encode_token
      if !encode_service.call
        raise ServiceError.new(encode_service.errors.first[:message])
      end
    end

    def issue_token
      if !issue_service.call
        raise ServiceError.new(issue_service.errors.first[:message])
      end
    end

    def compose_token_pair
      self.output = {
        access_token: encode_service.output[:token],
        refresh_token: issue_service.output[:raw_token]
      }
    end

    def encode_service
      @encode_service ||= AccessTokens::EncodeService.new(payload: { sub: input[:user].id })
    end

    def issue_service
      @issue_service ||= RefreshTokens::IssueService.new(user: input[:user])
    end
  end
end
