require "rails_helper"

RSpec.describe RefreshToken, type: :model do
  describe "associations" do
    it "belongs to a user" do
      token = create(:refresh_token)
      expect(token.user).to be_a(User)
    end
  end

  describe ".active scope" do
    it "includes a valid, non-revoked, non-expired token" do
      token = create(:refresh_token)
      expect(RefreshToken.active).to include(token)
    end

    it "excludes a revoked token" do
      token = create(:refresh_token, :revoked)
      expect(RefreshToken.active).not_to include(token)
    end

    it "excludes an expired token" do
      token = create(:refresh_token, :expired)
      expect(RefreshToken.active).not_to include(token)
    end

    it "excludes a token that is both revoked and expired" do
      token = create(:refresh_token, :revoked, :expired)
      expect(RefreshToken.active).not_to include(token)
    end
  end
end
