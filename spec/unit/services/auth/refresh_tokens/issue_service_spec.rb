require "rails_helper"

module Auth
  module RefreshTokens
    RSpec.describe IssueService do
      let(:user) { create(:user) }

      def issue(user)
        service = described_class.new(user: user)
        service.call
        service
      end

      describe "#call" do
        it "creates a RefreshToken record for the user" do
          expect { described_class.new(user: user).call }.to change(user.refresh_tokens, :count).by(1)
        end

        it "outputs the raw token string" do
          service = issue(user)
          expect(service.output[:raw_token]).to be_a(String)
          expect(service.output[:raw_token]).not_to be_empty
        end

        it "stores a SHA-256 digest of the raw token, not the raw token itself" do
          service = issue(user)
          record = user.refresh_tokens.last
          expect(record.token_digest).to eq(Digest::SHA256.hexdigest(service.output[:raw_token]))
          expect(record.token_digest).not_to eq(service.output[:raw_token])
        end

        it "sets expires_at approximately 90 days from now" do
          issue(user)
          record = user.refresh_tokens.last
          expect(record.expires_at).to be_within(5.seconds).of(90.days.from_now)
        end

        it "creates the token with revoked_at as nil" do
          issue(user)
          record = user.refresh_tokens.last
          expect(record.revoked_at).to be_nil
        end
      end
    end
  end
end
