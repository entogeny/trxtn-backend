require "rails_helper"

module Events
  RSpec.describe IndexService do
    subject(:service) { described_class.new }

    describe "#call" do
      let!(:later_event)  { create(:event, start_at: 30.days.from_now) }
      let!(:earlier_event) { create(:event, start_at: 1.day.from_now) }

      it "returns true" do
        expect(service.call).to be true
      end

      it "exposes events ordered by start_at ascending" do
        service.call
        expect(service.output[:records].to_a).to eq([ earlier_event, later_event ])
      end

      it "does not set output before call" do
        expect(service.output).to eq({})
      end
    end
  end
end
