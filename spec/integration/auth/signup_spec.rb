require "rails_helper"

RSpec.describe "POST /api/rest/v1/auth/signup" do
  let(:valid_params) do
    { username: "newuser", password: "password123", password_confirmation: "password123" }
  end

  context "with valid params" do
    it "returns 201 with an access token and refresh token" do
      post "/api/rest/v1/auth/signup", params: valid_params
      expect(response).to have_http_status(:created)
      expect(json).to include("access_token", "refresh_token")
    end

    it "creates a new user in the database" do
      expect { post "/api/rest/v1/auth/signup", params: valid_params }.to change(User, :count).by(1)
    end
  end

  context "with a mismatched password confirmation" do
    it "returns 422" do
      post "/api/rest/v1/auth/signup", params: valid_params.merge(password_confirmation: "different")
      expect(response).to have_http_status(422)
      expect(json).to have_key("errors")
    end
  end

  context "with a duplicate username" do
    it "returns 422" do
      create(:user, username: "newuser")
      post "/api/rest/v1/auth/signup", params: valid_params
      expect(response).to have_http_status(422)
      expect(json["errors"]).to be_present
    end
  end

  context "with an invalid username format" do
    it "returns 422 for a username with special characters" do
      post "/api/rest/v1/auth/signup", params: valid_params.merge(username: "bad user!")
      expect(response).to have_http_status(422)
      expect(json["errors"]).to be_present
    end
  end

  context "with a missing username" do
    it "returns 422" do
      post "/api/rest/v1/auth/signup", params: valid_params.merge(username: nil)
      expect(response).to have_http_status(422)
    end
  end
end
