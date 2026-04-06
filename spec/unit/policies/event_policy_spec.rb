require "rails_helper"

RSpec.describe EventPolicy do
  subject { described_class.new(user, record) }

  let(:user)   { build(:user) }
  let(:record) { build(:event) }

  describe "#index?" do
    it "returns true" do
      expect(subject.index?).to be true
    end
  end

  describe "#show?" do
    it "returns true" do
      expect(subject.show?).to be true
    end
  end

  describe "#create?" do
    context "when user is present" do
      it "returns true" do
        expect(subject.create?).to be true
      end
    end

    context "when user is nil" do
      let(:user) { nil }

      it "returns false" do
        expect(subject.create?).to be false
      end
    end
  end

  describe "#update?" do
    context "when user is the owner" do
      let(:user)   { create(:user) }
      let(:record) { build(:event, owner: user) }

      it "returns true" do
        expect(subject.update?).to be true
      end
    end

    context "when user is not the owner" do
      let(:user)   { create(:user) }
      let(:owner)  { create(:user) }
      let(:record) { build(:event, owner: owner) }

      it "returns false" do
        expect(subject.update?).to be false
      end
    end

    context "when user is nil" do
      let(:user)   { nil }
      let(:record) { build(:event, owner: create(:user)) }

      it "returns false" do
        expect(subject.update?).to be false
      end
    end
  end

  describe "#destroy?" do
    context "when user is the owner" do
      let(:user)   { create(:user) }
      let(:record) { build(:event, owner: user) }

      it "returns true" do
        expect(subject.destroy?).to be true
      end
    end

    context "when user is not the owner" do
      let(:user)   { create(:user) }
      let(:owner)  { create(:user) }
      let(:record) { build(:event, owner: owner) }

      it "returns false" do
        expect(subject.destroy?).to be false
      end
    end

    context "when user is nil" do
      let(:user)   { nil }
      let(:record) { build(:event, owner: create(:user)) }

      it "returns false" do
        expect(subject.destroy?).to be false
      end
    end
  end

  describe "Scope" do
    subject { EventPolicy::Scope.new(user, scope) }

    let(:scope) { Event }

    describe "#resolve" do
      it "returns all records" do
        expect(subject.resolve).to eq(Event.all)
      end
    end
  end
end
