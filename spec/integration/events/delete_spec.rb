require "rails_helper"

RSpec.describe "DELETE /api/rest/v1/events/:id" do
  let(:owner) { create(:user) }
  let!(:event) do
    create(:event,
      owner:       owner,
      creator:     owner,
      name:        "Test Event",
      description: "A test event description",
      start_at:    7.days.from_now)
  end

  context "with auth as owner" do
    it "returns 204 No Content" do
      delete "/api/rest/v1/events/#{event.id}", headers: auth_headers(owner)
      expect(response).to have_http_status(:no_content)
    end

    it "soft-deletes the event" do
      delete "/api/rest/v1/events/#{event.id}", headers: auth_headers(owner)
      expect(event.reload).to be_soft_deleted
    end
  end

  context "without authentication" do
    it "returns 401 Unauthorized" do
      delete "/api/rest/v1/events/#{event.id}"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when the user is not the owner" do
    let(:other_user) { create(:user) }

    it "returns 403 Forbidden" do
      delete "/api/rest/v1/events/#{event.id}", headers: auth_headers(other_user)
      expect(response).to have_http_status(:forbidden)
    end

    it "returns an errors array in the response body" do
      delete "/api/rest/v1/events/#{event.id}", headers: auth_headers(other_user)
      expect(json["errors"]).to be_present
    end
  end

  context "when the event does not exist" do
    it "returns 404 Not Found" do
      delete "/api/rest/v1/events/#{SecureRandom.uuid}", headers: auth_headers(owner)
      expect(response).to have_http_status(:not_found)
    end

    it "returns an errors array in the response body" do
      delete "/api/rest/v1/events/#{SecureRandom.uuid}", headers: auth_headers(owner)
      expect(json["errors"]).to be_present
    end
  end

  context "when the delete service fails" do
    before do
      allow_any_instance_of(Events::DeleteService).to receive(:call).and_return(false)
      allow_any_instance_of(Events::DeleteService).to receive(:errors).and_return([ { message: "Could not delete" } ])
    end

    it "returns 422 Unprocessable Content" do
      delete "/api/rest/v1/events/#{event.id}", headers: auth_headers(owner)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns an errors array in the response body" do
      delete "/api/rest/v1/events/#{event.id}", headers: auth_headers(owner)
      expect(json["errors"]).to be_present
    end
  end
end
