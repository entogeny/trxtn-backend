require "rails_helper"

RSpec.describe ApplicationService do
  describe "#initialize" do
    it "yields to a block when given" do
      block_called = false
      described_class.new { block_called = true }
      expect(block_called).to be true
    end
  end
end
