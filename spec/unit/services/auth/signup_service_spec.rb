require "rails_helper"

module Auth
  RSpec.describe SignupService do
    def signup(attributes = {})
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
          expect(signup.success?).to be true
        end

        it "creates a user in the database" do
          expect { signup }.to change(User, :count).by(1)
        end

        it "outputs an access token and refresh token" do
          service = signup
          expect(service.output).to include(:access_token, :refresh_token)
        end
      end

      context "when user creation fails" do
        it "returns false" do
          service = signup(username: "")
          expect(service.success?).to be false
        end

        it "does not create a user" do
          expect { signup(username: "") }.not_to change(User, :count)
        end

        it "surfaces the error" do
          service = signup(username: "")
          expect(service.errors.first[:message]).to be_present
        end
      end

      context "when token pair issuance fails" do
        before do
          allow_any_instance_of(TokenPairService).to receive(:call).and_return(false)
          allow_any_instance_of(TokenPairService).to receive(:errors).and_return([ { message: "token issue failed" } ])
        end

        it "returns false" do
          expect(signup.success?).to be false
        end

        it "rolls back user creation" do
          expect { signup }.not_to change(User, :count)
        end

        it "surfaces the token pair error" do
          service = signup
          expect(service.errors.first[:message]).to eq("token issue failed")
        end
      end
    end
  end
end
