require "rails_helper"

module Auth
  RSpec.describe LoginService do
    let!(:user) { create(:user, username: "alice", password: "password123", password_confirmation: "password123") }

    def login(attributes = {})
      defaults = { username: "alice", password: "password123" }
      service = described_class.new(defaults.merge(attributes))
      service.call
      service
    end

    describe "#call" do
      context "with valid credentials" do
        it "returns true" do
          expect(login.success?).to be true
        end

        it "outputs an access token and refresh token" do
          service = login
          expect(service.output).to include(:access_token, :refresh_token)
        end
      end

      context "with a case-insensitive username match" do
        it "returns true when username is provided in a different case" do
          expect(login(username: "ALICE").success?).to be true
        end
      end

      context "with an unknown username" do
        it "returns false" do
          expect(login(username: "nobody").success?).to be false
        end

        it "returns an intentionally vague error" do
          service = login(username: "nobody")
          expect(service.errors.first[:message]).to eq("Invalid username or password")
        end
      end

      context "with the wrong password" do
        it "returns false" do
          expect(login(password: "wrongpassword").success?).to be false
        end

        it "returns an intentionally vague error" do
          service = login(password: "wrongpassword")
          expect(service.errors.first[:message]).to eq("Invalid username or password")
        end
      end

      context "when TokenPairService fails" do
        before do
          allow_any_instance_of(TokenPairService).to receive(:call).and_return(false)
          allow_any_instance_of(TokenPairService).to receive(:errors).and_return([ { message: "token issue failed" } ])
        end

        it "returns false" do
          expect(login.success?).to be false
        end

        it "surfaces the token pair error" do
          service = login
          expect(service.errors.first[:message]).to eq("token issue failed")
        end
      end
    end
  end
end
