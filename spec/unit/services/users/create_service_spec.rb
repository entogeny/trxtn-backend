require "rails_helper"

module Users
  RSpec.describe CreateService do
    def create(attributes = {})
      defaults = {
        username: "alice",
        password: "password123",
        password_confirmation: "password123"
      }
      service = described_class.new(defaults.merge(attributes))
      service.call
      service
    end

    describe "#call" do
      context "with valid attributes" do
        it "returns true" do
          expect(create.success?).to be true
        end

        it "creates a User record" do
          expect { create }.to change(User, :count).by(1)
        end

        it "outputs the created user" do
          service = create
          expect(service.output[:user]).to be_a(User)
          expect(service.output[:user]).to be_persisted
        end

        it "stores the correct username" do
          service = create(username: "bobby")
          expect(service.output[:user].username).to eq("bobby")
        end
      end

      context "with invalid attributes" do
        it "returns false for a duplicate username" do
          create(username: "alice")
          service = create(username: "alice")
          expect(service.success?).to be false
        end

        it "returns errors for a duplicate username" do
          create(username: "alice")
          service = create(username: "alice")
          expect(service.errors.map { |e| e[:message] }).to include("Username has already been taken")
        end

        it "returns false for a missing username" do
          service = create(username: "")
          expect(service.success?).to be false
        end

        it "does not create a user for a missing username" do
          expect { create(username: "") }.not_to change(User, :count)
        end

        it "returns false when password confirmation does not match" do
          service = create(password_confirmation: "different")
          expect(service.success?).to be false
        end
      end
    end
  end
end
