require "rails_helper"

RSpec.describe "GET /api/rest/v1/events" do
  context "when there are events" do
    let!(:first_event)  { create(:event, start_at: 1.day.from_now) }
    let!(:second_event) { create(:event, start_at: 2.days.from_now) }

    it "returns 200 OK" do
      get "/api/rest/v1/events"
      expect(response).to have_http_status(:ok)
    end

    it "returns events ordered by start_at ascending" do
      get "/api/rest/v1/events"
      expect(JSON.parse(response.body).map { |e| e["id"] }).to eq([ first_event.id, second_event.id ])
    end

    it "returns the expected event shape" do
      get "/api/rest/v1/events"
      expect(JSON.parse(response.body).first.keys).to match_array(%w[id name description start_at end_at created_at updated_at])
    end
  end

  context "when there are no events" do
    it "returns an empty array" do
      get "/api/rest/v1/events"
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end
  end

  context "authentication" do
    it "does not require authentication" do
      get "/api/rest/v1/events"
      expect(response).not_to have_http_status(:unauthorized)
    end
  end

  context "when the service fails" do
    before do
      allow_any_instance_of(Events::IndexService).to receive(:call).and_return(false)
      allow_any_instance_of(Events::IndexService).to receive(:errors).and_return([ { message: "something went wrong" } ])
    end

    it "returns 500 internal server error" do
      get "/api/rest/v1/events"
      expect(response).to have_http_status(:internal_server_error)
    end
  end
end
