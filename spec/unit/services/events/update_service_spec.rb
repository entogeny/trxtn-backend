require "rails_helper"

module Events
  RSpec.describe UpdateService do
    let!(:owner) { create(:user) }
    let!(:event) do
      create(:event,
        owner:       owner,
        creator:     owner,
        name:        "Original Name",
        description: "Original description",
        start_at:    7.days.from_now)
    end

    def update(record_data = {})
      defaults = {
        description: "Updated description",
        name:        "Updated Name",
        start_at:    7.days.from_now
      }

      service = described_class.new(
        id:          event.id,
        record_data: defaults.merge(record_data)
      )
      service.call
      service
    end

    describe "#call" do
      context "with valid attributes" do
        it "returns true" do
          expect(update.success?).to be true
        end

        it "updates the name" do
          update(name: "A New Name")
          expect(event.reload.name).to eq("A New Name")
        end

        it "updates the description" do
          update(description: "A new description")
          expect(event.reload.description).to eq("A new description")
        end

        it "updates the start_at" do
          new_time = 14.days.from_now
          update(start_at: new_time)
          expect(event.reload.start_at).to be_within(1.second).of(new_time)
        end

        it "outputs the updated event" do
          service = update
          expect(service.output[:record]).to be_a(Event)
          expect(service.output[:record].id).to eq(event.id)
        end

        it "can transfer ownership" do
          new_owner = create(:user)
          update(owner_id: new_owner.id)
          expect(event.reload.owner).to eq(new_owner)
        end

        it "can clear ownership" do
          update(owner_id: nil)
          expect(event.reload.owner).to be_nil
        end

        it "does not raise when owner_id is unchanged" do
          expect(update.success?).to be true
        end
      end

      context "with invalid attributes" do
        it "returns false for a blank name" do
          expect(update(name: nil).success?).to be false
        end

        it "does not update the record for a blank name" do
          update(name: nil)
          expect(event.reload.name).to eq("Original Name")
        end

        it "returns errors for a blank name" do
          service = update(name: nil)
          expect(service.errors.map { |e| e[:message] }).to be_present
        end

        it "returns false for a blank description" do
          expect(update(description: nil).success?).to be false
        end

        it "does not apply future validation when start_at is nil" do
          # start_at being nil skips the future check but still fails model presence validation
          service = update(start_at: nil)
          expect(service.errors.map { |e| e[:message] }).not_to include(match(/future/))
        end

        it "returns false for a past start_at" do
          expect(update(start_at: 1.day.ago).success?).to be false
        end

        it "includes 'future' in the error message for a past start_at" do
          service = update(start_at: 1.day.ago)
          expect(service.errors.first[:message]).to include("future")
        end

        it "returns false when end_at is before start_at" do
          expect(update(start_at: 3.days.from_now, end_at: 2.days.from_now).success?).to be false
        end

        it "returns false for a non-existent owner_id" do
          expect(update(owner_id: SecureRandom.uuid).success?).to be false
        end

        it "includes 'Owner' in the error message for a non-existent owner_id" do
          service = update(owner_id: SecureRandom.uuid)
          expect(service.errors.first[:message]).to include("Owner")
        end
      end

      context "when the event does not exist" do
        it "returns false" do
          service = described_class.new(
            id:          SecureRandom.uuid,
            record_data: { name: "X", description: "Y", start_at: 1.day.from_now }
          )
          service.call
          expect(service.success?).to be false
        end

        it "populates an error message" do
          service = described_class.new(
            id:          SecureRandom.uuid,
            record_data: { name: "X", description: "Y", start_at: 1.day.from_now }
          )
          service.call
          expect(service.errors.map { |e| e[:message] }).to be_present
        end
      end
    end
  end
end
