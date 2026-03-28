require "rails_helper"

module Base
  RSpec.describe DeleteService do
    def make_soft_deletable_record(soft_delete_result: true, deleted: false, error_messages: [])
      soft_delete_res = soft_delete_result
      is_deleted = deleted
      msgs = error_messages
      record = Object.new
      record.define_singleton_method(:soft_deleted?) { is_deleted }
      record.define_singleton_method(:soft_delete) { soft_delete_res }
      record.define_singleton_method(:destroy) { true }
      record.define_singleton_method(:errors) { Struct.new(:full_messages).new(msgs) }
      fake_class = Object.new
      fake_class.define_singleton_method(:include?) { |mod| mod == SoftDeletable }
      fake_class.define_singleton_method(:name) { "FakeModel" }
      record.define_singleton_method(:class) { fake_class }
      record
    end

    def make_hard_delete_only_record(destroy_result:, error_messages: [])
      destroy_res = destroy_result
      msgs = error_messages
      record = Object.new
      record.define_singleton_method(:destroy) { destroy_res }
      record.define_singleton_method(:errors) { Struct.new(:full_messages).new(msgs) }
      fake_class = Object.new
      fake_class.define_singleton_method(:include?) { |_mod| false }
      fake_class.define_singleton_method(:name) { "FakeModel" }
      record.define_singleton_method(:class) { fake_class }
      record
    end

    def build_service(input)
      Class.new(described_class).new(input)
    end

    def build_service_with_find(record: nil, find_succeeds: true, error_messages: [])
      fake_record = record
      succeeds = find_succeeds
      msgs = error_messages
      Class.new(described_class) do
        define_method(:find_record) do
          if succeeds
            fake_record
          else
            raise ServiceError.new(msgs.join(", "))
          end
        end
        private :find_record
      end.new(id: 1)
    end

    describe "#model" do
      it "raises MissingDefinitionError when not overridden" do
        expect { described_class.new(id: 1).call }.to raise_error(MissingDefinitionError, /#model must be implemented/)
      end
    end

    describe "#call" do
      context "with strategy: :soft (default)" do
        context "when the record supports soft delete and is not deleted" do
          let(:record) { make_soft_deletable_record(soft_delete_result: true) }
          subject(:service) { build_service(record: record) }

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
          subject(:service) { build_service(record: record) }

          it "returns false" do
            expect(service.call).to be false
          end

          it "populates an already deleted error" do
            service.call
            expect(service.errors.map { |e| e[:message] }).to include("Record is already deleted")
          end
        end

        context "when the model does not support soft delete" do
          let(:record) { make_hard_delete_only_record(destroy_result: true) }
          subject(:service) { build_service(record: record) }

          it "returns false" do
            expect(service.call).to be false
          end

          it "populates a soft delete not supported error" do
            service.call
            expect(service.errors.map { |e| e[:message] }).to include("FakeModel does not support soft delete")
          end
        end

        context "when soft_delete returns false" do
          let(:record) { make_soft_deletable_record(soft_delete_result: false, error_messages: [ "Validation failed" ]) }
          subject(:service) { build_service(record: record) }

          it "returns false" do
            expect(service.call).to be false
          end

          it "populates errors from the record" do
            service.call
            expect(service.errors.map { |e| e[:message] }).to include("Validation failed")
          end
        end
      end

      context "with an unknown strategy" do
        let(:record) { make_hard_delete_only_record(destroy_result: true) }
        subject(:service) { build_service(record: record, strategy: :unknown) }

        it "returns false" do
          expect(service.call).to be false
        end

        it "populates an unknown strategy error" do
          service.call
          expect(service.errors.map { |e| e[:message] }).to include("Unknown strategy: unknown. Must be :soft or :hard")
        end
      end

      context "with strategy: :hard" do
        context "and the record destroys successfully" do
          let(:record) { make_hard_delete_only_record(destroy_result: true) }
          subject(:service) { build_service(record: record, strategy: :hard) }

          it "returns true" do
            expect(service.call).to be true
          end

          it "exposes the destroyed record in output" do
            service.call
            expect(service.output[:record]).to eq(record)
          end
        end

        context "and the record fails to destroy" do
          let(:record) { make_hard_delete_only_record(destroy_result: false, error_messages: [ "Cannot delete record" ]) }
          subject(:service) { build_service(record: record, strategy: :hard) }

          it "returns false" do
            expect(service.call).to be false
          end

          it "populates errors from the record's messages" do
            service.call
            expect(service.errors.map { |error| error[:message] }).to include("Cannot delete record")
          end
        end
      end

      context "when an id is provided" do
        context "and the record is found" do
          let(:record) { make_soft_deletable_record(soft_delete_result: true) }
          subject(:service) { build_service_with_find(record: record) }

          it "returns true" do
            expect(service.call).to be true
          end

          it "exposes the record in output" do
            service.call
            expect(service.output[:record]).to eq(record)
          end
        end

        context "and the record is not found" do
          subject(:service) { build_service_with_find(find_succeeds: false, error_messages: [ "Unable to find record by identifier: 0" ]) }

          it "returns false" do
            service.call
            expect(service.success?).to be false
          end

          it "populates an error message" do
            service.call
            expect(service.errors.map { |error| error[:message] }).to include("Unable to find record by identifier: 0")
          end
        end
      end

      context "when neither a record nor an id is provided" do
        subject(:service) { build_service({}) }

        it "returns false" do
          expect(service.call).to be false
        end

        it "populates an error message" do
          service.call
          expect(service.errors.map { |error| error[:message] }).to include("A record or id must be provided")
        end
      end
    end
  end
end
