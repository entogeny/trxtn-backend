require "rails_helper"

module Base
  RSpec.describe HardDeleteService do
      def make_record(destroy_result:, error_messages: [])
        destroy_res = destroy_result
        msgs = error_messages
        record = Object.new
        record.define_singleton_method(:destroy) { destroy_res }
        record.define_singleton_method(:errors) { Struct.new(:full_messages).new(msgs) }
        record
      end

      describe "#call" do
        context "when the record destroys successfully" do
          let(:record) { make_record(destroy_result: true) }
          subject(:service) { described_class.new(record: record) }

          it "returns true" do
            expect(service.call).to be true
          end

          it "exposes the record in output" do
            service.call
            expect(service.output[:record]).to eq(record)
          end
        end

        context "when the record fails to destroy" do
          let(:record) { make_record(destroy_result: false, error_messages: [ "Cannot delete record" ]) }
          subject(:service) { described_class.new(record: record) }

          it "returns false" do
            expect(service.call).to be false
          end

          it "populates errors from the record" do
            service.call
            expect(service.errors.map { |e| e[:message] }).to include("Cannot delete record")
          end
        end

        context "when no record is provided" do
          subject(:service) { described_class.new({}) }

          it "returns false" do
            expect(service.call).to be false
          end

          it "populates an error message" do
            service.call
            expect(service.errors.map { |e| e[:message] }).to include("A record must be provided")
          end
        end
      end
  end
end
