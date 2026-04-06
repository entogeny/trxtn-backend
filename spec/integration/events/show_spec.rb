require "rails_helper"

RSpec.describe "GET /api/rest/v1/events/:id" do
  let!(:event) { create(:event) }

  context "when the event exists" do
    it "returns 200 OK" do
      get "/api/rest/v1/events/#{event.id}"
      expect(response).to have_http_status(:ok)
    end

    it "returns the expected event shape" do
      get "/api/rest/v1/events/#{event.id}"
      expect(json["data"].keys).to match_array(%w[id name description start_at end_at])
    end

    it "returns the correct event" do
      get "/api/rest/v1/events/#{event.id}"
      expect(json["data"]["id"]).to eq(event.id)
    end
  end

  context "when the event does not exist" do
    it "returns 404 not found" do
      get "/api/rest/v1/events/#{SecureRandom.uuid}"
      expect(response).to have_http_status(:not_found)
    end

    it "returns an errors array in the response body" do
      get "/api/rest/v1/events/#{SecureRandom.uuid}"
      expect(json["errors"]).to be_present
    end
  end

  context "authentication" do
    it "does not require authentication" do
      get "/api/rest/v1/events/#{event.id}"
      expect(response).not_to have_http_status(:unauthorized)
    end
  end

  context "when authorization is denied" do
    before do
      allow_any_instance_of(EventPolicy).to receive(:show?).and_return(false)
    end

    it "returns 403 forbidden" do
      get "/api/rest/v1/events/#{event.id}"
      expect(response).to have_http_status(:forbidden)
    end

    it "returns an errors array in the response body" do
      get "/api/rest/v1/events/#{event.id}"
      expect(json["errors"]).to be_present
    end
  end
end
