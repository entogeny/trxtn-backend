require "rails_helper"

module Base
  RSpec.describe SoftDeleteService do
      def make_soft_deletable_record(soft_delete_result: true, deleted: false, error_messages: [])
        soft_delete_res = soft_delete_result
        is_deleted = deleted
        msgs = error_messages
        record = Object.new
        record.define_singleton_method(:soft_deleted?) { is_deleted }
        record.define_singleton_method(:soft_delete) { soft_delete_res }
        record.define_singleton_method(:errors) { Struct.new(:full_messages).new(msgs) }
        fake_class = Object.new
        fake_class.define_singleton_method(:include?) { |mod| mod == SoftDeletable }
        fake_class.define_singleton_method(:name) { "FakeModel" }
        record.define_singleton_method(:class) { fake_class }
        record
      end

      def make_non_soft_deletable_record
        record = Object.new
        fake_class = Object.new
        fake_class.define_singleton_method(:include?) { |_mod| false }
        fake_class.define_singleton_method(:name) { "FakeModel" }
        record.define_singleton_method(:class) { fake_class }
        record
      end

      describe "#call" do
        context "when the record supports soft delete and is not deleted" do
          let(:record) { make_soft_deletable_record(soft_delete_result: true) }
          subject(:service) { described_class.new(record: record) }

          it "returns true" do
            expect(service.call).to be true
          end

          it "exposes the record in output" do
            service.call
            expect(service.output[:record]).to eq(record)
          end
        end

        context "when the record is already deleted" do
          let(:record) { make_soft_deletable_record(deleted: true) }
          subject(:service) { described_class.new(record: record) }

          it "returns false" do
            expect(service.call).to be false
          end

          it "populates an already deleted error" do
            service.call
            expect(service.errors.map { |e| e[:message] }).to include("Record is already deleted")
          end
        end

        context "when the record does not support soft delete" do
          let(:record) { make_non_soft_deletable_record }
          subject(:service) { described_class.new(record: record) }

          it "returns false" do
            expect(service.call).to be false
          end

          it "populates a not supported error" do
            service.call
            expect(service.errors.map { |e| e[:message] }).to include("FakeModel does not support soft delete")
          end
        end

        context "when soft_delete returns false" do
          let(:record) { make_soft_deletable_record(soft_delete_result: false, error_messages: [ "Validation failed" ]) }
          subject(:service) { described_class.new(record: record) }

          it "returns false" do
            expect(service.call).to be false
          end

          it "populates errors from the record" do
            service.call
            expect(service.errors.map { |e| e[:message] }).to include("Validation failed")
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
