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
