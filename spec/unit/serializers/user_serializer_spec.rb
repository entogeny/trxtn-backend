require "rails_helper"

RSpec.describe UserSerializer do
  let(:user) { build(:user) }

  describe ":base view" do
    it "includes only id" do
      result = JSON.parse(UserSerializer.render(user, view: :base))
      expect(result.keys).to match_array(%w[id])
    end
  end

  describe ":standard view" do
    it "includes id and username" do
      result = JSON.parse(UserSerializer.render(user, view: :standard))
      expect(result.keys).to match_array(%w[id username])
    end
  end

  describe ":extended view" do
    it "includes at least the standard fields" do
      result = JSON.parse(UserSerializer.render(user, view: :extended))
      expect(result.keys).to include(*%w[id username])
    end
  end
end
