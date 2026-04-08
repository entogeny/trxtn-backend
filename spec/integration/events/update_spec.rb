require "rails_helper"

RSpec.describe "PATCH /api/rest/v1/events/:id" do
  let(:owner) { create(:user) }
  let!(:event) do
    create(:event,
      owner:       owner,
      creator:     owner,
      name:        "Original Name",
      description: "Original description",
      start_at:    7.days.from_now)
  end

  let(:valid_params) do
    {
      event: {
        description: "Updated description",
        name:        "Updated Name",
        start_at:    14.days.from_now.iso8601
      }
    }
  end

  context "with valid params and auth as owner" do
    it "returns 200 OK" do
      patch "/api/rest/v1/events/#{event.id}", params: valid_params, headers: auth_headers(owner)
      expect(response).to have_http_status(:ok)
    end

    it "returns the expected event shape" do
      patch "/api/rest/v1/events/#{event.id}", params: valid_params, headers: auth_headers(owner)
      expect(json["data"].keys).to match_array(%w[id name description start_at end_at owner])
    end

    it "reflects the updated name" do
      patch "/api/rest/v1/events/#{event.id}", params: valid_params, headers: auth_headers(owner)
      expect(json["data"]["name"]).to eq("Updated Name")
    end
  end

  context "without authentication" do
    it "returns 401 Unauthorized" do
      patch "/api/rest/v1/events/#{event.id}", params: valid_params
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when the user is not the owner" do
    let(:other_user) { create(:user) }

    it "returns 403 Forbidden" do
      patch "/api/rest/v1/events/#{event.id}", params: valid_params, headers: auth_headers(other_user)
      expect(response).to have_http_status(:forbidden)
    end

    it "returns an errors array in the response body" do
      patch "/api/rest/v1/events/#{event.id}", params: valid_params, headers: auth_headers(other_user)
      expect(json["errors"]).to be_present
    end
  end

  context "when the event does not exist" do
    it "returns 404 Not Found" do
      patch "/api/rest/v1/events/#{SecureRandom.uuid}", params: valid_params, headers: auth_headers(owner)
      expect(response).to have_http_status(:not_found)
    end

    it "returns an errors array in the response body" do
      patch "/api/rest/v1/events/#{SecureRandom.uuid}", params: valid_params, headers: auth_headers(owner)
      expect(json["errors"]).to be_present
    end
  end

  context "with missing name" do
    it "returns 422 Unprocessable Content" do
      patch "/api/rest/v1/events/#{event.id}", params: valid_params.deep_merge(event: { name: nil }), headers: auth_headers(owner)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns errors in the response body" do
      patch "/api/rest/v1/events/#{event.id}", params: valid_params.deep_merge(event: { name: nil }), headers: auth_headers(owner)
      expect(json["errors"]).to be_present
    end
  end

  context "with missing description" do
    it "returns 422 Unprocessable Content" do
      patch "/api/rest/v1/events/#{event.id}", params: valid_params.deep_merge(event: { description: nil }), headers: auth_headers(owner)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  context "with start_at in the past" do
    it "returns 422 Unprocessable Content" do
      patch "/api/rest/v1/events/#{event.id}", params: valid_params.deep_merge(event: { start_at: 1.day.ago.iso8601 }), headers: auth_headers(owner)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns errors in the response body" do
      patch "/api/rest/v1/events/#{event.id}", params: valid_params.deep_merge(event: { start_at: 1.day.ago.iso8601 }), headers: auth_headers(owner)
      expect(json["errors"]).to be_present
    end
  end

  context "with end_at before start_at" do
    it "returns 422 Unprocessable Content" do
      patch "/api/rest/v1/events/#{event.id}", params: valid_params.deep_merge(event: { end_at: 1.hour.ago.iso8601 }), headers: auth_headers(owner)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
