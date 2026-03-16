require "rails_helper"

RSpec.describe "Protected endpoints" do
  let(:user) { create(:user) }

  context "with no Authorization header" do
    it "returns 401 with a missing token error" do
      get "/api/rest/v1/test/protected"
      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]).to eq("Missing token")
    end
  end

  context "with an expired JWT" do
    it "returns 401 with a token expired error" do
      expired_token = JWT.encode(
        { sub: user.id, exp: 1.hour.ago.to_i },
        Rails.application.credentials.jwt_secret_key!,
        "HS256"
      )
      get "/api/rest/v1/test/protected", headers: { "Authorization" => "Bearer #{expired_token}" }
      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]).to eq("Token has expired")
    end
  end

  context "with a malformed JWT" do
    it "returns 401 with an invalid token error" do
      get "/api/rest/v1/test/protected", headers: { "Authorization" => "Bearer not.a.valid.token" }
      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]).to eq("Invalid token")
    end
  end

  context "with a valid JWT" do
    it "returns 200" do
      get "/api/rest/v1/test/protected", headers: auth_headers(user)
      expect(response).to have_http_status(:ok)
    end
  end
end
