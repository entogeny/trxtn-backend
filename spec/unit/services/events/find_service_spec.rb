require "rails_helper"

module Events
  RSpec.describe FindService do
    let!(:event) { create(:event) }

    def find(identifier)
      service = described_class.new(identifier: identifier)
      service.call
      service
    end

    describe "#call" do
      context "when found by id" do
        it "returns true" do
          expect(find(event.id).success?).to be true
        end

        it "outputs the correct event" do
          expect(find(event.id).output[:record]).to eq(event)
        end
      end

      context "when the event does not exist" do
        it "returns false" do
          expect(find(SecureRandom.uuid).success?).to be false
        end

        it "adds an error referencing the identifier" do
          fake_id = SecureRandom.uuid
          service = find(fake_id)
          expect(service.errors.first[:message]).to include(fake_id)
        end
      end
    end
  end
end
