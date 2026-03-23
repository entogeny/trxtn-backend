require "rails_helper"

module Users
  RSpec.describe FindService do
    let!(:user) { create(:user) }

    def find(identifier)
      service = described_class.new(identifier: identifier)
      service.call
      service
    end

    describe "#call" do
      context "when found by id" do
        it "returns true" do
          expect(find(user.id).success?).to be true
        end

        it "outputs the correct user" do
          service = find(user.id)
          expect(service.output[:record]).to eq(user)
        end
      end

      context "when the user does not exist" do
        it "returns false" do
          expect(find(0).success?).to be false
        end

        it "adds an error referencing the identifier" do
          service = find(0)
          expect(service.errors.first[:message]).to include("0")
        end
      end
    end
  end
end
