require "rails_helper"

module Auth
  module RefreshTokens
    RSpec.describe RevokeService do
      let(:user) { create(:user) }

      describe ".call" do
        context "with a valid token" do
          it "sets revoked_at on the token record" do
            raw_token = Auth::RefreshTokens::IssueService.call(user)
            described_class.call(raw_token)
            record = RefreshToken.find_by(token_digest: Digest::SHA256.hexdigest(raw_token))
            expect(record.revoked_at).not_to be_nil
          end
        end

        context "with an unknown token" do
          it "raises TokenNotFound" do
            expect { described_class.call("unknown_raw_token") }.to raise_error(Auth::Errors::TokenNotFound)
          end
        end

        context "with an already-revoked token" do
          it "raises TokenRevoked" do
            raw_token = Auth::RefreshTokens::IssueService.call(user)
            described_class.call(raw_token)
            expect { described_class.call(raw_token) }.to raise_error(Auth::Errors::TokenRevoked)
          end
        end
      end
    end
  end
end
