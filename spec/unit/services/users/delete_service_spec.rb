require "rails_helper"

module Users
  RSpec.describe DeleteService do
    let!(:user) { create(:user) }

    def delete(attributes = {})
      defaults = { id: user.id }
      service = described_class.new(defaults.merge(attributes))
      service.call
      service
    end

    describe "#call" do
      context "with default strategy (:soft)" do
        it "returns true" do
          expect(delete.success?).to be true
        end

        it "sets deleted_at on the user" do
          expect { delete }.to change { user.reload.deleted_at }.from(nil)
        end

        it "does not remove the user from the database" do
          expect { delete }.not_to change(User, :count)
        end

        it "outputs the soft-deleted user" do
          service = delete
          expect(service.output[:record]).to be_a(User)
          expect(service.output[:record].id).to eq(user.id)
        end

        context "when the user is already soft-deleted" do
          let!(:user) { create(:user, :deleted) }

          it "returns false" do
            expect(delete.success?).to be false
          end

          it "populates a not found error (FindService excludes soft-deleted records)" do
            expect(delete.errors.map { |e| e[:message] }).to be_present
          end

          it "raises not found rather than already deleted when passing by id" do
            expect(delete.errors.first[:message]).to include(user.id.to_s)
          end

          it "returns already deleted error when record is passed directly" do
            service = described_class.new(record: user, strategy: :soft)
            service.call
            expect(service.errors.map { |e| e[:message] }).to include("Record is already deleted")
          end
        end
      end

      context "with strategy: :hard" do
        it "returns true" do
          expect(delete(strategy: :hard).success?).to be true
        end

        it "removes the user from the database" do
          expect { delete(strategy: :hard) }.to change(User, :count).by(-1)
        end

        it "outputs the destroyed user" do
          service = delete(strategy: :hard)
          expect(service.output[:record]).to be_a(User)
          expect(service.output[:record].id).to eq(user.id)
        end
      end

      context "when the user does not exist" do
        it "returns false" do
          expect(delete(id: 0).success?).to be false
        end

        it "populates an error message" do
          expect(delete(id: 0).errors.map { |e| e[:message] }).to be_present
        end
      end
    end
  end
end
