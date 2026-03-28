require "rails_helper"

RSpec.describe SoftDeletable do
  # Use User as the test model — it includes SoftDeletable
  let!(:user) { create(:user) }
  let!(:deleted_user) { create(:user, :deleted) }

  describe "scopes" do
    describe ".not_soft_deleted" do
      it "returns only records without a deleted_at" do
        expect(User.not_soft_deleted).to include(user)
        expect(User.not_soft_deleted).not_to include(deleted_user)
      end
    end

    describe ".soft_deleted" do
      it "returns only records with a deleted_at" do
        expect(User.soft_deleted).to include(deleted_user)
        expect(User.soft_deleted).not_to include(user)
      end
    end
  end

  describe "#soft_delete" do
    context "when the record is not deleted" do
      it "sets deleted_at to the current time" do
        expect { user.soft_delete }.to change { user.reload.deleted_at }.from(nil)
      end

      it "returns true" do
        expect(user.soft_delete).to be true
      end
    end

    context "when the record is already deleted" do
      it "returns false without updating deleted_at" do
        original_deleted_at = deleted_user.deleted_at
        result = deleted_user.soft_delete
        expect(result).to be false
        expect(deleted_user.reload.deleted_at).to be_within(1.second).of(original_deleted_at)
      end
    end
  end

  describe "#soft_undelete" do
    context "when the record is deleted" do
      it "clears deleted_at" do
        expect { deleted_user.soft_undelete }.to change { deleted_user.reload.deleted_at }.to(nil)
      end

      it "returns true" do
        expect(deleted_user.soft_undelete).to be true
      end
    end

    context "when the record is not deleted" do
      it "returns false without modifying the record" do
        expect(user.soft_undelete).to be false
        expect(user.reload.deleted_at).to be_nil
      end
    end
  end

  describe "#soft_deleted?" do
    it "returns true when deleted_at is set" do
      expect(deleted_user.soft_deleted?).to be true
    end

    it "returns false when deleted_at is nil" do
      expect(user.soft_deleted?).to be false
    end
  end

  describe "#not_soft_deleted?" do
    it "returns true when deleted_at is nil" do
      expect(user.not_soft_deleted?).to be true
    end

    it "returns false when deleted_at is set" do
      expect(deleted_user.not_soft_deleted?).to be false
    end
  end
end
