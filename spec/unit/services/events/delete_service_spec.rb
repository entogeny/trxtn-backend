require "rails_helper"

module Events
  RSpec.describe DeleteService do
    let!(:event) { create(:event, :with_owner) }

    def delete_event(input = {})
      service = described_class.new({ record: event }.merge(input))
      service.call
      service
    end

    describe "#call" do
      context "with a valid record" do
        it "returns true" do
          expect(delete_event.success?).to be true
        end

        it "soft-deletes the event" do
          delete_event
          expect(event.reload).to be_soft_deleted
        end

        it "outputs the deleted record" do
          service = delete_event
          expect(service.output[:record]).to eq(event)
        end
      end

      context "when the event is already deleted" do
        before { event.soft_delete }

        it "returns false" do
          expect(delete_event.success?).to be false
        end

        it "includes 'already deleted' in the error message" do
          service = delete_event
          expect(service.errors.first[:message]).to include("already deleted")
        end
      end

      context "when an id is provided and the event exists" do
        it "returns true" do
          service = described_class.new(id: event.id)
          service.call
          expect(service.success?).to be true
        end

        it "soft-deletes the event" do
          described_class.new(id: event.id).call
          expect(event.reload).to be_soft_deleted
        end
      end

      context "when the event does not exist" do
        it "returns false" do
          service = described_class.new(id: SecureRandom.uuid)
          service.call
          expect(service.success?).to be false
        end

        it "populates an error message" do
          service = described_class.new(id: SecureRandom.uuid)
          service.call
          expect(service.errors).to be_present
        end
      end
    end
  end
end
