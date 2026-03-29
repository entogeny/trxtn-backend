require "rails_helper"

module Base
  RSpec.describe DeleteService do
    def make_record
      record = Object.new
      record.define_singleton_method(:destroy) { true }
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
        context "when the sub-service succeeds" do
          let(:record) { make_record }
          let(:fake_output) { { record: record } }

          subject(:service) { build_service(record: record) }

          before do
            sub = instance_double(Base::SoftDeleteService, call: true, success?: true, output: fake_output, errors: [])
            allow(Base::SoftDeleteService).to receive(:new).with(record: record).and_return(sub)
          end

          it "returns true" do
            expect(service.call).to be true
          end

          it "propagates the sub-service output" do
            service.call
            expect(service.output[:record]).to eq(record)
          end
        end

        context "when the sub-service fails" do
          let(:record) { make_record }
          subject(:service) { build_service(record: record) }

          before do
            sub = instance_double(Base::SoftDeleteService, call: false, success?: false, output: {}, errors: [ { message: "Record is already deleted" } ])
            allow(Base::SoftDeleteService).to receive(:new).with(record: record).and_return(sub)
          end

          it "returns false" do
            expect(service.call).to be false
          end

          it "propagates errors from the sub-service" do
            service.call
            expect(service.errors.map { |e| e[:message] }).to include("Record is already deleted")
          end
        end
      end

      context "with strategy: :hard" do
        context "when the sub-service succeeds" do
          let(:record) { make_record }
          let(:fake_output) { { record: record } }
          subject(:service) { build_service(record: record, strategy: :hard) }

          before do
            sub = instance_double(Base::HardDeleteService, call: true, success?: true, output: fake_output, errors: [])
            allow(Base::HardDeleteService).to receive(:new).with(record: record).and_return(sub)
          end

          it "returns true" do
            expect(service.call).to be true
          end

          it "propagates the sub-service output" do
            service.call
            expect(service.output[:record]).to eq(record)
          end
        end

        context "when the sub-service fails" do
          let(:record) { make_record }
          subject(:service) { build_service(record: record, strategy: :hard) }

          before do
            sub = instance_double(Base::HardDeleteService, call: false, success?: false, output: {}, errors: [ { message: "Cannot delete record" } ])
            allow(Base::HardDeleteService).to receive(:new).with(record: record).and_return(sub)
          end

          it "returns false" do
            expect(service.call).to be false
          end

          it "propagates errors from the sub-service" do
            service.call
            expect(service.errors.map { |e| e[:message] }).to include("Cannot delete record")
          end
        end
      end

      context "with an unknown strategy" do
        let(:record) { make_record }
        subject(:service) { build_service(record: record, strategy: :unknown) }

        it "returns false" do
          expect(service.call).to be false
        end

        it "populates an unknown strategy error" do
          service.call
          expect(service.errors.map { |e| e[:message] }).to include("Unknown strategy: unknown. Must be :soft or :hard")
        end
      end

      context "when an id is provided" do
        context "and the record is found" do
          let(:record) { make_record }
          subject(:service) { build_service_with_find(record: record) }

          before do
            sub = instance_double(Base::SoftDeleteService, call: true, success?: true, output: { record: record }, errors: [])
            allow(Base::SoftDeleteService).to receive(:new).with(record: record).and_return(sub)
          end

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
            expect(service.call).to be false
          end

          it "populates an error message" do
            service.call
            expect(service.errors.map { |e| e[:message] }).to include("Unable to find record by identifier: 0")
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
          expect(service.errors.map { |e| e[:message] }).to include("A record or id must be provided")
        end
      end
    end
  end
end
