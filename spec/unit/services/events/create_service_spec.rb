require "rails_helper"

module Events
  RSpec.describe CreateService do
    let(:user) { create(:user) }

    def create_event(record_data = {}, current_user: user)
      service = described_class.new(
        current_user: current_user,
        record_data: {
          description: "A test event description",
          end_at:      nil,
          name:        "Test Event",
          start_at:    1.day.from_now
        }.merge(record_data)
      )
      service.call
      service
    end

    describe "#call" do
      context "with valid params" do
        it "returns true" do
          expect(create_event.success?).to be true
        end

        it "outputs a persisted Event record" do
          service = create_event
          expect(service.output[:record]).to be_a(Event).and be_persisted
        end

        it "sets owner to the given user" do
          service = create_event
          expect(service.output[:record].owner).to eq(user)
        end

        it "sets creator to the given user" do
          service = create_event
          expect(service.output[:record].creator).to eq(user)
        end
      end

      context "without a name" do
        it "returns false" do
          expect(create_event({ name: nil }).success?).to be false
        end

        it "does not persist a record" do
          service = create_event({ name: nil })
          expect(service.output[:record]).to be_nil
        end
      end

      context "without a description" do
        it "returns false" do
          expect(create_event({ description: nil }).success?).to be false
        end
      end

      context "without a start_at" do
        it "returns false" do
          expect(create_event({ start_at: nil }).success?).to be false
        end
      end

      context "with start_at in the past" do
        it "returns false" do
          expect(create_event({ start_at: 1.day.ago }).success?).to be false
        end

        it "includes 'future' in the error message" do
          service = create_event({ start_at: 1.day.ago })
          expect(service.errors.first[:message]).to include("future")
        end
      end

      context "with end_at before start_at" do
        it "returns false" do
          expect(create_event({ start_at: 2.days.from_now, end_at: 1.day.from_now }).success?).to be false
        end

        it "includes 'end_at' in the error message" do
          service = create_event({ start_at: 2.days.from_now, end_at: 1.day.from_now })
          expect(service.errors.first[:message]).to include("End at")
        end
      end

      context "with end_at equal to start_at" do
        it "returns false" do
          time = 2.days.from_now
          expect(create_event({ start_at: time, end_at: time }).success?).to be false
        end
      end
    end
  end
end
