require "rails_helper"

module Users
  RSpec.describe UndeleteService do
    let!(:deleted_user) { create(:user, :deleted) }

    def undelete(attributes = {})
      defaults = { id: deleted_user.id }
      service = described_class.new(defaults.merge(attributes))
      service.call
      service
    end

    describe "#call" do
      context "with a valid id for a soft-deleted user" do
        it "returns true" do
          expect(undelete.success?).to be true
        end

        it "clears deleted_at on the user" do
          expect { undelete }.to change { deleted_user.reload.deleted_at }.to(nil)
        end

        it "does not change the user count" do
          expect { undelete }.not_to change(User, :count)
        end

        it "outputs the restored user" do
          service = undelete
          expect(service.output[:record]).to be_a(User)
          expect(service.output[:record].id).to eq(deleted_user.id)
        end
      end

      context "when the user is not deleted" do
        let!(:active_user) { create(:user) }

        it "returns false" do
          service = described_class.new(id: active_user.id)
          service.call
          expect(service.success?).to be false
        end

        it "populates an error message" do
          service = described_class.new(id: active_user.id)
          service.call
          expect(service.errors.map { |e| e[:message] }).to include("Record is not deleted")
        end
      end

      context "when the user does not exist" do
        it "returns false" do
          expect(undelete(id: 0).success?).to be false
        end

        it "populates an error message" do
          expect(undelete(id: 0).errors.map { |e| e[:message] }).to be_present
        end
      end
    end
  end
end
