require "rails_helper"

RSpec.describe "POST /api/rest/v1/auth/login" do
  let!(:user) { create(:user, username: "Alice", password: "password123", password_confirmation: "password123") }

  context "with correct credentials" do
    it "returns 200 with an access token and refresh token" do
      post "/api/rest/v1/auth/login", params: { username: "Alice", password: "password123" }
      expect(response).to have_http_status(:ok)
      expect(json).to include("access_token", "refresh_token")
    end
  end

  context "with a case-insensitive username match" do
    it "returns 200 when username is provided in different case" do
      post "/api/rest/v1/auth/login", params: { username: "alice", password: "password123" }
      expect(response).to have_http_status(:ok)
      expect(json).to include("access_token", "refresh_token")
    end
  end

  context "with the wrong password" do
    it "returns 401 with an error message" do
      post "/api/rest/v1/auth/login", params: { username: "Alice", password: "wrongpassword" }
      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]).to eq("Invalid username or password")
    end
  end

  context "with an unknown username" do
    it "returns 401 with an error message" do
      post "/api/rest/v1/auth/login", params: { username: "nobody", password: "password123" }
      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]).to eq("Invalid username or password")
    end
  end
end
