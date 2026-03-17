require "rails_helper"

module Auth
  RSpec.describe TokenPairService do
    let(:user) { create(:user) }

    def issue(user)
      service = described_class.new(user: user)
      service.call
      service
    end

    describe "#call" do
      it "returns true" do
        expect(issue(user).success?).to be true
      end

      it "outputs an access token and refresh token" do
        service = issue(user)
        expect(service.output).to include(:access_token, :refresh_token)
      end

      it "creates a refresh token record for the user" do
        expect { issue(user) }.to change(user.refresh_tokens, :count).by(1)
      end

      it "outputs a non-empty access token string" do
        service = issue(user)
        expect(service.output[:access_token]).to be_a(String).and be_present
      end

      it "outputs a non-empty refresh token string" do
        service = issue(user)
        expect(service.output[:refresh_token]).to be_a(String).and be_present
      end

      context "when EncodeService fails" do
        before do
          allow_any_instance_of(AccessTokens::EncodeService).to receive(:call).and_return(false)
          allow_any_instance_of(AccessTokens::EncodeService).to receive(:errors).and_return([ { message: "encoding failed" } ])
        end

        it "returns false" do
          expect(issue(user).success?).to be false
        end

        it "surfaces the encode error" do
          service = issue(user)
          expect(service.errors.first[:message]).to eq("encoding failed")
        end
      end

      context "when IssueService fails" do
        before do
          allow_any_instance_of(RefreshTokens::IssueService).to receive(:call).and_return(false)
          allow_any_instance_of(RefreshTokens::IssueService).to receive(:errors).and_return([ { message: "issue failed" } ])
        end

        it "returns false" do
          expect(issue(user).success?).to be false
        end

        it "surfaces the issue error" do
          service = issue(user)
          expect(service.errors.first[:message]).to eq("issue failed")
        end
      end
    end
  end
end
