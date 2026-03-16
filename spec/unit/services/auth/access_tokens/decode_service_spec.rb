require "rails_helper"

module Auth
  module AccessTokens
    RSpec.describe DecodeService do
      let(:secret) { Rails.application.credentials.jwt_secret_key! }

      def encode_token(payload)
        service = Auth::AccessTokens::EncodeService.new(payload: payload)
        service.call
        service.output[:token]
      end

      def decode(token)
        described_class.new(token: token).tap(&:call)
      end

      describe "#call" do
        it "decodes a valid token and returns the payload" do
          token = encode_token({ sub: 1 })
          service = decode(token)
          expect(service.output[:payload][:sub]).to eq(1)
        end

        it "returns a payload with indifferent access" do
          token = encode_token({ sub: 1 })
          service = decode(token)
          expect(service.output[:payload]["sub"]).to eq(service.output[:payload][:sub])
        end

        it "fails with an error for an expired token" do
          expired_token = JWT.encode({ sub: 1, exp: 1.hour.ago.to_i }, secret, "HS256")
          service = decode(expired_token)
          expect(service.success?).to be false
          expect(service.errors.first[:message]).to eq("Token has expired")
        end

        it "fails with an error for a malformed token" do
          service = decode("not.a.token")
          expect(service.success?).to be false
          expect(service.errors.first[:message]).to eq("Invalid token")
        end

        it "fails with an error for a token signed with the wrong secret" do
          wrong_token = JWT.encode({ sub: 1, exp: 1.hour.from_now.to_i }, "wrong_secret", "HS256")
          service = decode(wrong_token)
          expect(service.success?).to be false
          expect(service.errors.first[:message]).to eq("Invalid token")
        end
      end
    end
  end
end
