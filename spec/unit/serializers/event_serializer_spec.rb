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
      expect(result.keys).to match_array(%w[id description end_at name start_at])
    end
  end

  describe ":extended view" do
    it "includes at least the standard fields" do
      result = JSON.parse(EventSerializer.render(event, view: :extended))
      expect(result.keys).to include(*%w[id description end_at name start_at])
    end
  end
end
