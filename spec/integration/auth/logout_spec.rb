require "rails_helper"

RSpec.describe "POST /auth/logout" do
  let(:user) { create(:user) }

  def issue_token(user)
    service = Auth::RefreshTokens::IssueService.new(user: user)
    service.call
    service.output[:raw_token]
  end

  context "with a valid refresh token" do
    let(:raw_token) { issue_token(user) }

    it "returns 204 No Content" do
      post "/auth/logout", params: { refresh_token: raw_token }
      expect(response).to have_http_status(:no_content)
    end

    it "revokes the token in the database" do
      post "/auth/logout", params: { refresh_token: raw_token }
      record = RefreshToken.find_by(token_digest: Digest::SHA256.hexdigest(raw_token))
      expect(record.revoked_at).not_to be_nil
    end
  end

  context "with an unknown refresh token" do
    it "returns 401" do
      post "/auth/logout", params: { refresh_token: "unknown_token" }
      expect(response).to have_http_status(:unauthorized)
      expect(json["errors"].first["message"]).to eq("Token not found")
    end
  end

  context "with an already-revoked refresh token" do
    it "returns 401" do
      raw_token = issue_token(user)
      Auth::RefreshTokens::RevokeService.new(raw_token: raw_token).call

      post "/auth/logout", params: { refresh_token: raw_token }
      expect(response).to have_http_status(:unauthorized)
      expect(json["errors"].first["message"]).to eq("Token has already been revoked")
    end
  end
end
