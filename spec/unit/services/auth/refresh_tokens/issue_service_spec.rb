require "rails_helper"

module Auth
  module RefreshTokens
    RSpec.describe IssueService do
      let(:user) { create(:user) }

      describe ".call" do
        it "creates a RefreshToken record for the user" do
          expect { described_class.call(user) }.to change(user.refresh_tokens, :count).by(1)
        end

        it "returns the raw token string" do
          raw_token = described_class.call(user)
          expect(raw_token).to be_a(String)
          expect(raw_token).not_to be_empty
        end

        it "stores a SHA-256 digest of the raw token, not the raw token itself" do
          raw_token = described_class.call(user)
          record = user.refresh_tokens.last
          expect(record.token_digest).to eq(Digest::SHA256.hexdigest(raw_token))
          expect(record.token_digest).not_to eq(raw_token)
        end

        it "sets expires_at approximately 90 days from now" do
          described_class.call(user)
          record = user.refresh_tokens.last
          expect(record.expires_at).to be_within(5.seconds).of(90.days.from_now)
        end

        it "creates the token with revoked_at as nil" do
          described_class.call(user)
          record = user.refresh_tokens.last
          expect(record.revoked_at).to be_nil
        end
      end
    end
  end
end
