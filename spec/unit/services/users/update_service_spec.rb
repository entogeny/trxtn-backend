require "rails_helper"

module Users
  RSpec.describe UpdateService do
    let!(:user) { create(:user, username: "alice") }

    def update(attributes = {})
      defaults = { id: user.id, username: "aliceupdated" }
      service = described_class.new(defaults.merge(attributes))
      service.call
      service
    end

    describe "#call" do
      context "with valid attributes" do
        it "returns true" do
          expect(update.success?).to be true
        end

        it "updates the username" do
          update(username: "bobbyupdated")
          expect(user.reload.username).to eq("bobbyupdated")
        end

        it "outputs the updated user" do
          service = update
          expect(service.output[:record]).to be_a(User)
          expect(service.output[:record].id).to eq(user.id)
        end
      end

      context "with invalid attributes" do
        it "returns false for a blank username" do
          expect(update(username: "").success?).to be false
        end

        it "does not update the record for a blank username" do
          update(username: "")
          expect(user.reload.username).to eq("alice")
        end

        it "returns errors for a blank username" do
          service = update(username: "")
          expect(service.errors.map { |e| e[:message] }).to be_present
        end

        it "returns false for a duplicate username" do
          create(:user, username: "takenusername")
          expect(update(username: "takenusername").success?).to be false
        end
      end

      context "when the user does not exist" do
        it "raises ActiveRecord::RecordNotFound" do
          expect { update(id: 0) }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end
