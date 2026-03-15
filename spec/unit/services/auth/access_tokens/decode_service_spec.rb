require "rails_helper"

module Auth
  module AccessTokens
    RSpec.describe DecodeService do
      let(:secret) { Rails.application.credentials.jwt_secret_key! }

      describe ".call" do
        it "decodes a valid token and returns the payload" do
          token = Auth::AccessTokens::EncodeService.call({ sub: 1 })
          payload = described_class.call(token)
          expect(payload[:sub]).to eq(1)
        end

        it "returns a payload with indifferent access" do
          token = Auth::AccessTokens::EncodeService.call({ sub: 1 })
          payload = described_class.call(token)
          expect(payload["sub"]).to eq(payload[:sub])
        end

        it "raises TokenExpired for an expired token" do
          expired_token = JWT.encode({ sub: 1, exp: 1.hour.ago.to_i }, secret, "HS256")
          expect { described_class.call(expired_token) }.to raise_error(Auth::Errors::TokenExpired)
        end

        it "raises TokenInvalid for a malformed token" do
          expect { described_class.call("not.a.token") }.to raise_error(Auth::Errors::TokenInvalid)
        end

        it "raises TokenInvalid for a token signed with the wrong secret" do
          wrong_token = JWT.encode({ sub: 1, exp: 1.hour.from_now.to_i }, "wrong_secret", "HS256")
          expect { described_class.call(wrong_token) }.to raise_error(Auth::Errors::TokenInvalid)
        end
      end
    end
  end
end
