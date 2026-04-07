require "rails_helper"

RSpec.describe "POST /api/rest/v1/events" do
  let(:user) { create(:user) }
  let(:valid_params) do
    {
      event: {
        description: "A test event description",
        name:        "Test Event",
        start_at:    1.day.from_now.iso8601
      }
    }
  end

  context "with valid params and auth" do
    it "returns 201 Created" do
      post "/api/rest/v1/events", params: valid_params, headers: auth_headers(user)
      expect(response).to have_http_status(:created)
    end

    it "returns the expected event shape" do
      post "/api/rest/v1/events", params: valid_params, headers: auth_headers(user)
      expect(json["data"].keys).to match_array(%w[id name description start_at end_at owner])
    end

    it "sets owner.id to the authenticated user's id" do
      post "/api/rest/v1/events", params: valid_params, headers: auth_headers(user)
      expect(json["data"]["owner"]["id"]).to eq(user.id)
    end
  end

  context "without authentication" do
    it "returns 401 Unauthorized" do
      post "/api/rest/v1/events", params: valid_params
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when authorization is denied" do
    before do
      allow_any_instance_of(EventPolicy).to receive(:create?).and_return(false)
    end

    it "returns 403 Forbidden" do
      post "/api/rest/v1/events", params: valid_params, headers: auth_headers(user)
      expect(response).to have_http_status(:forbidden)
    end

    it "returns an errors array in the response body" do
      post "/api/rest/v1/events", params: valid_params, headers: auth_headers(user)
      expect(json["errors"]).to be_present
    end
  end

  context "with missing name" do
    it "returns 422 Unprocessable Content" do
      post "/api/rest/v1/events", params: valid_params.deep_merge(event: { name: nil }), headers: auth_headers(user)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns errors in the response body" do
      post "/api/rest/v1/events", params: valid_params.deep_merge(event: { name: nil }), headers: auth_headers(user)
      expect(json["errors"]).to be_present
    end
  end

  context "with missing description" do
    it "returns 422 Unprocessable Content" do
      post "/api/rest/v1/events", params: valid_params.deep_merge(event: { description: nil }), headers: auth_headers(user)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  context "with missing start_at" do
    it "returns 422 Unprocessable Content" do
      post "/api/rest/v1/events", params: valid_params.deep_merge(event: { start_at: nil }), headers: auth_headers(user)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  context "with start_at in the past" do
    it "returns 422 Unprocessable Content" do
      post "/api/rest/v1/events", params: valid_params.deep_merge(event: { start_at: 1.day.ago.iso8601 }), headers: auth_headers(user)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns errors in the response body" do
      post "/api/rest/v1/events", params: valid_params.deep_merge(event: { start_at: 1.day.ago.iso8601 }), headers: auth_headers(user)
      expect(json["errors"]).to be_present
    end
  end

  context "with end_at before start_at" do
    it "returns 422 Unprocessable Content" do
      post "/api/rest/v1/events", params: valid_params.deep_merge(event: { end_at: 1.hour.ago.iso8601 }), headers: auth_headers(user)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
