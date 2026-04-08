require "rails_helper"

RSpec.describe EventSerializer do
  let(:event) { build(:event) }

  describe ":base view" do
    it "includes only the id" do
      result = JSON.parse(EventSerializer.render(event, view: :base))
      expect(result.keys).to match_array(%w[id])
    end
  end

  describe ":standard view" do
    it "includes the expected fields" do
      result = JSON.parse(EventSerializer.render(event, view: :standard))
      expect(result.keys).to match_array(%w[id description end_at name start_at owner])
    end

    it "renders owner at base view" do
      user   = build(:user)
      event  = build(:event, owner: user)
      result = JSON.parse(EventSerializer.render(event, view: :standard))
      expect(result["owner"].keys).to match_array(%w[id])
    end

    it "renders owner as null when not set" do
      result = JSON.parse(EventSerializer.render(event, view: :standard))
      expect(result["owner"]).to be_nil
    end
  end

  describe ":extended view" do
    it "includes at least the standard fields" do
      result = JSON.parse(EventSerializer.render(event, view: :extended))
      expect(result.keys).to include(*%w[id description end_at name start_at owner])
    end

    it "renders owner at standard view" do
      user   = build(:user)
      event  = build(:event, owner: user)
      result = JSON.parse(EventSerializer.render(event, view: :extended))
      expect(result["owner"].keys).to match_array(%w[id username])
    end
  end
end
