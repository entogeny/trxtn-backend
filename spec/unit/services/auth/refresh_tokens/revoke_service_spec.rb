require "rails_helper"

module Auth
  module RefreshTokens
    RSpec.describe RevokeService do
      let(:user) { create(:user) }

      def issue_token
        service = Auth::RefreshTokens::IssueService.new(user: user)
        service.call
        service.output[:raw_token]
      end

      describe "#call" do
        context "with a valid token" do
          it "sets revoked_at on the token record" do
            raw_token = issue_token
            described_class.new(raw_token: raw_token).call
            record = RefreshToken.find_by(token_digest: Digest::SHA256.hexdigest(raw_token))
            expect(record.revoked_at).not_to be_nil
          end
        end

        context "with an unknown token" do
          it "fails with a token not found error" do
            service = described_class.new(raw_token: "unknown_raw_token")
            expect(service.call).to be false
            expect(service.errors.first[:message]).to eq("Token not found")
          end
        end

        context "with an already-revoked token" do
          it "fails with a token revoked error" do
            raw_token = issue_token
            described_class.new(raw_token: raw_token).call
            service = described_class.new(raw_token: raw_token)
            expect(service.call).to be false
            expect(service.errors.first[:message]).to eq("Token has already been revoked")
          end
        end
      end
    end
  end
end
