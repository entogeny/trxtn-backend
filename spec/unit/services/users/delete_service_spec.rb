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
      context "with a valid id" do
        it "returns true" do
          expect(delete.success?).to be true
        end

        it "removes the user from the database" do
          expect { delete }.to change(User, :count).by(-1)
        end

        it "outputs the destroyed user" do
          service = delete
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
