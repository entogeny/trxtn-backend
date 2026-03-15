require "rails_helper"

RSpec.describe "POST /auth/refresh" do
  let(:user) { create(:user) }

  context "with a valid refresh token" do
    let(:raw_token) { Auth::RefreshTokens::IssueService.call(user) }

    it "returns 200 with a new access token and refresh token" do
      post "/auth/refresh", params: { refresh_token: raw_token }
      expect(response).to have_http_status(:ok)
      expect(json).to include("access_token", "refresh_token")
    end

    it "revokes the old refresh token in the database" do
      post "/auth/refresh", params: { refresh_token: raw_token }
      record = RefreshToken.find_by(token_digest: Digest::SHA256.hexdigest(raw_token))
      expect(record.revoked_at).not_to be_nil
    end

    it "returns a new refresh token different from the original" do
      post "/auth/refresh", params: { refresh_token: raw_token }
      expect(json["refresh_token"]).not_to eq(raw_token)
    end
  end

  context "with an expired refresh token" do
    it "returns 401" do
      token_record = create(:refresh_token, :expired, user: user)
      raw_token = "expired_raw"
      allow(RefreshToken).to receive(:find_by).and_return(token_record)

      post "/auth/refresh", params: { refresh_token: raw_token }
      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]).to eq("Invalid or expired refresh token")
    end
  end

  context "with a revoked refresh token" do
    it "returns 401" do
      raw_token = Auth::RefreshTokens::IssueService.call(user)
      Auth::RefreshTokens::RevokeService.call(raw_token)

      post "/auth/refresh", params: { refresh_token: raw_token }
      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]).to eq("Invalid or expired refresh token")
    end
  end

  context "with an unknown refresh token" do
    it "returns 401" do
      post "/auth/refresh", params: { refresh_token: "unknown_token" }
      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]).to eq("Invalid or expired refresh token")
    end
  end
end
