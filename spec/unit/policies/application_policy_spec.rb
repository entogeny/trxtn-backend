require "rails_helper"

RSpec.describe ApplicationPolicy do
  subject { described_class.new(user, record) }

  let(:user)   { build(:user) }
  let(:record) { double("record") }

  describe "#index?" do
    it "returns false" do
      expect(subject.index?).to be false
    end
  end

  describe "#show?" do
    it "returns false" do
      expect(subject.show?).to be false
    end
  end

  describe "#create?" do
    it "returns false" do
      expect(subject.create?).to be false
    end
  end

  describe "#update?" do
    it "returns false" do
      expect(subject.update?).to be false
    end
  end

  describe "#destroy?" do
    it "returns false" do
      expect(subject.destroy?).to be false
    end
  end

  describe "Scope" do
    subject { ApplicationPolicy::Scope.new(user, scope) }

    let(:scope) { double("scope") }

    describe "#resolve" do
      it "raises NotImplementedError" do
        expect { subject.resolve }.to raise_error(NotImplementedError, /has not implemented #resolve/)
      end
    end
  end
end
