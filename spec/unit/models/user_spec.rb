require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    describe "username" do
      it "is invalid without a username" do
        user = build(:user, username: nil)
        expect(user).not_to be_valid
        expect(user.errors[:username]).to include("can't be blank")
      end

      it "is invalid when username is too short" do
        user = build(:user, username: "ab")
        expect(user).not_to be_valid
        expect(user.errors[:username]).to include("is too short (minimum is 3 characters)")
      end

      it "is invalid when username is too long" do
        user = build(:user, username: "a" * 31)
        expect(user).not_to be_valid
        expect(user.errors[:username]).to include("is too long (maximum is 30 characters)")
      end

      it "is invalid with special characters" do
        user = build(:user, username: "bad user!")
        expect(user).not_to be_valid
        expect(user.errors[:username]).to include("can only contain letters, numbers, and underscores")
      end

      it "is invalid with a space" do
        user = build(:user, username: "bad user")
        expect(user).not_to be_valid
        expect(user.errors[:username]).to include("can only contain letters, numbers, and underscores")
      end

      it "is valid with letters, numbers, and underscores" do
        user = build(:user, username: "valid_user_123")
        expect(user).to be_valid
      end

      it "is invalid when username is already taken (case-insensitive)" do
        create(:user, username: "Alice")
        user = build(:user, username: "alice")
        expect(user).not_to be_valid
        expect(user.errors[:username]).to include("has already been taken")
      end
    end

    describe "password" do
      it "is invalid without a password" do
        user = build(:user, password: nil, password_confirmation: nil)
        expect(user).not_to be_valid
      end
    end
  end

  describe "#authenticate" do
    let(:user) { create(:user, password: "secret123", password_confirmation: "secret123") }

    it "returns the user when given the correct password" do
      expect(user.authenticate("secret123")).to eq(user)
    end

    it "returns false when given the wrong password" do
      expect(user.authenticate("wrongpassword")).to be_falsey
    end
  end

  describe "associations" do
    it "has many refresh_tokens" do
      user = create(:user)
      token1 = create(:refresh_token, user: user)
      token2 = create(:refresh_token, user: user)
      expect(user.refresh_tokens).to include(token1, token2)
    end

    it "destroys associated refresh_tokens when user is deleted" do
      user = create(:user)
      create(:refresh_token, user: user)
      expect { user.destroy }.to change(RefreshToken, :count).by(-1)
    end
  end
end
