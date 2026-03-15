require "rails_helper"

module Auth
  module RefreshTokens
    RSpec.describe RotateService do
      let(:user) { create(:user) }

      before do
        allow(Auth::RefreshTokens::IssueService).to receive(:call).and_return("new_raw_token")
        allow(Auth::AccessTokens::EncodeService).to receive(:call).and_return("new_jwt")
      end

      describe ".call" do
        context "with a valid token" do
          let(:raw_token) { SecureRandom.hex(32) }
          let!(:token_record) do
            create(:refresh_token, user: user, token_digest: Digest::SHA256.hexdigest(raw_token))
          end

          it "returns a token pair" do
            result = described_class.call(raw_token)
            expect(result).to include(access_token: "new_jwt", refresh_token: "new_raw_token")
          end

          it "revokes the old token record" do
            described_class.call(raw_token)
            record = RefreshToken.find_by(token_digest: Digest::SHA256.hexdigest(raw_token))
            expect(record.revoked_at).not_to be_nil
          end

          it "issues a new refresh token for the user" do
            described_class.call(raw_token)
            expect(Auth::RefreshTokens::IssueService).to have_received(:call).with(user)
          end

          it "encodes a new access token with the user's id" do
            described_class.call(raw_token)
            expect(Auth::AccessTokens::EncodeService).to have_received(:call).with({ sub: user.id })
          end
        end

        context "with an unknown token" do
          it "raises TokenNotFound" do
            expect { described_class.call("unknown") }.to raise_error(Auth::Errors::TokenNotFound)
          end
        end

        context "with a revoked token" do
          it "raises TokenRevoked" do
            token_record = create(:refresh_token, :revoked, user: user)
            raw_token = "some_token"
            allow(RefreshToken).to receive(:find_by).and_return(token_record)
            expect { described_class.call(raw_token) }.to raise_error(Auth::Errors::TokenRevoked)
          end
        end

        context "with an expired token" do
          it "raises TokenExpired" do
            token_record = create(:refresh_token, :expired, user: user)
            raw_token = "some_token"
            allow(RefreshToken).to receive(:find_by).and_return(token_record)
            expect { described_class.call(raw_token) }.to raise_error(Auth::Errors::TokenExpired)
          end
        end

        context "when IssueService raises during rotation" do
          it "rolls back the revocation of the old token" do
            raw_token = SecureRandom.hex(32)
            create(:refresh_token, user: user, token_digest: Digest::SHA256.hexdigest(raw_token))

            allow(Auth::RefreshTokens::IssueService).to receive(:call).and_raise(StandardError, "issue failed")

            expect { described_class.call(raw_token) }.to raise_error(StandardError)

            record = RefreshToken.find_by(token_digest: Digest::SHA256.hexdigest(raw_token))
            expect(record.revoked_at).to be_nil
          end
        end
      end
    end
  end
end
