require "rails_helper"

module Auth
  module RefreshTokens
    RSpec.describe RotateService do
      let(:user) { create(:user) }

      describe "#call" do
        context "with a valid token" do
          let(:raw_token) { SecureRandom.hex(32) }
          let!(:token_record) do
            create(:refresh_token, user: user, token_digest: Digest::SHA256.hexdigest(raw_token))
          end

          it "returns true" do
            service = described_class.new(raw_token: raw_token)
            expect(service.call).to be true
          end

          it "outputs an access token and refresh token" do
            service = described_class.new(raw_token: raw_token)
            service.call
            expect(service.output).to include(:access_token, :refresh_token)
          end

          it "revokes the old token record" do
            described_class.new(raw_token: raw_token).call
            record = RefreshToken.find_by(token_digest: Digest::SHA256.hexdigest(raw_token))
            expect(record.revoked_at).not_to be_nil
          end

          it "issues a new refresh token for the user" do
            described_class.new(raw_token: raw_token).call
            expect(user.refresh_tokens.count).to eq(2)
          end
        end

        context "with an unknown token" do
          it "fails with a token not found error" do
            service = described_class.new(raw_token: "unknown")
            expect(service.call).to be false
            expect(service.errors.first[:message]).to eq("Token not found")
          end
        end

        context "with a revoked token" do
          it "fails with a token revoked error" do
            token_record = create(:refresh_token, :revoked, user: user)
            allow(RefreshToken).to receive(:find_by).and_return(token_record)
            service = described_class.new(raw_token: "some_token")
            expect(service.call).to be false
            expect(service.errors.first[:message]).to eq("Token has been revoked")
          end
        end

        context "with an expired token" do
          it "fails with a token expired error" do
            token_record = create(:refresh_token, :expired, user: user)
            allow(RefreshToken).to receive(:find_by).and_return(token_record)
            service = described_class.new(raw_token: "some_token")
            expect(service.call).to be false
            expect(service.errors.first[:message]).to eq("Token has expired")
          end
        end

        context "when IssueService fails during rotation" do
          it "rolls back the revocation of the old token" do
            raw_token = SecureRandom.hex(32)
            create(:refresh_token, user: user, token_digest: Digest::SHA256.hexdigest(raw_token))

            allow_any_instance_of(IssueService).to receive(:call).and_return(false)
            allow_any_instance_of(IssueService).to receive(:errors).and_return([ { message: "issue failed" } ])

            described_class.new(raw_token: raw_token).call

            record = RefreshToken.find_by(token_digest: Digest::SHA256.hexdigest(raw_token))
            expect(record.revoked_at).to be_nil
          end
        end
      end
    end
  end
end
