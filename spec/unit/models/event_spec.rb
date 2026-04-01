require "rails_helper"

RSpec.describe Event, type: :model do
  describe "validations" do
    describe ":description" do
      it "is invalid without a description" do
        event = build(:event, description: nil)
        expect(event).not_to be_valid
        expect(event.errors[:description]).to include("can't be blank")
      end
    end

    describe ":end_at" do
      context "when end_at is present" do
        it "is invalid when end_at is before start_at" do
          event = build(:event, start_at: 2.days.from_now, end_at: 1.day.from_now)
          expect(event).not_to be_valid
          expect(event.errors[:end_at]).to include("must be after start_at")
        end

        it "is invalid when end_at equals start_at" do
          time = 2.days.from_now
          event = build(:event, start_at: time, end_at: time)
          expect(event).not_to be_valid
          expect(event.errors[:end_at]).to include("must be after start_at")
        end

        it "is valid when end_at is after start_at" do
          event = build(:event, start_at: 2.days.from_now, end_at: 3.days.from_now)
          expect(event).to be_valid
        end

        it "skips the comparison when start_at is blank" do
          event = build(:event, start_at: nil, end_at: 1.day.from_now)
          event.valid?
          expect(event.errors[:end_at]).to be_empty
        end
      end

      context "when end_at is nil" do
        it "does not validate end_at" do
          event = build(:event, end_at: nil)
          event.valid?
          expect(event.errors[:end_at]).to be_empty
        end
      end
    end

    describe ":name" do
      it "is invalid without a name" do
        event = build(:event, name: nil)
        expect(event).not_to be_valid
        expect(event.errors[:name]).to include("can't be blank")
      end
    end

    describe ":start_at" do
      it "is invalid without a start_at" do
        event = build(:event, start_at: nil)
        expect(event).not_to be_valid
        expect(event.errors[:start_at]).to include("can't be blank")
      end
    end
  end
end
