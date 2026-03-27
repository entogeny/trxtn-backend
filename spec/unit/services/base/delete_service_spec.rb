require "rails_helper"

module Base
  RSpec.describe DeleteService do
    def make_fake_record(destroy_result:, error_messages: [])
      Class.new do
        define_method(:destroy) { destroy_result }
        define_method(:errors) { Struct.new(:full_messages).new(error_messages) }
      end.new
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
      context "when a record is provided directly" do
        context "and destroys successfully" do
          let(:record) { make_fake_record(destroy_result: true) }
          subject(:service) { build_service(record: record) }

          it "returns true" do
            expect(service.call).to be true
          end

          it "exposes the destroyed record in output" do
            service.call
            expect(service.output[:record]).to eq(record)
          end
        end

        context "and fails to destroy" do
          let(:record) { make_fake_record(destroy_result: false, error_messages: [ "Cannot delete record" ]) }
          subject(:service) { build_service(record: record) }

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
        context "and the record is found and destroys successfully" do
          let(:record) { make_fake_record(destroy_result: true) }
          subject(:service) { build_service_with_find(record: record) }

          it "returns true" do
            expect(service.call).to be true
          end

          it "exposes the destroyed record in output" do
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
