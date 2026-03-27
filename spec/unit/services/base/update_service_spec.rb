require "rails_helper"

module Base
  RSpec.describe UpdateService do
    def make_fake_record(save_result:, error_messages: [])
      Class.new do
        define_method(:assign_attributes) { |*| }
        define_method(:save) { save_result }
        define_method(:errors) { Struct.new(:full_messages).new(error_messages) }
      end.new
    end

    def make_fake_find_service(success:, record: nil, error_messages: [])
      svc = Object.new
      svc.define_singleton_method(:call) { }
      svc.define_singleton_method(:success?) { success }
      if success
        svc.define_singleton_method(:output) { { record: record } }
      else
        svc.define_singleton_method(:errors) { error_messages.map { |m| { message: m } } }
      end
      svc
    end

    def build_service(fake_find_service, id: 1)
      Class.new(described_class) do
        define_method(:model) { Object.new }
        define_method(:find_service) { fake_find_service }
        private :model, :find_service
      end.new(id: id)
    end

    describe "#model" do
      it "raises MissingDefinitionError when not overridden" do
        expect { described_class.new(id: 1).call }.to raise_error(MissingDefinitionError, /#model must be implemented/)
      end
    end

    describe "#call" do
      context "when the record is found and saves successfully" do
        let(:record) { make_fake_record(save_result: true) }
        subject(:service) { build_service(make_fake_find_service(success: true, record: record)) }

        it "returns true" do
          expect(service.call).to be true
        end

        it "exposes the record in output" do
          service.call
          expect(service.output[:record]).to eq(record)
        end
      end

      context "when the record is found but fails to save" do
        let(:record) { make_fake_record(save_result: false, error_messages: [ "Name can't be blank" ]) }
        subject(:service) { build_service(make_fake_find_service(success: true, record: record)) }

        it "returns false" do
          expect(service.call).to be false
        end

        it "populates errors from the record's validation messages" do
          service.call
          expect(service.errors.map { |e| e[:message] }).to include("Name can't be blank")
        end
      end

      context "when the record is not found" do
        subject(:service) { build_service(make_fake_find_service(success: false, error_messages: [ "Unable to find record by identifier: 0" ])) }

        it "returns false" do
          service.call
          expect(service.success?).to be false
        end

        it "populates an error message" do
          service.call
          expect(service.errors.map { |e| e[:message] }).to include("Unable to find record by identifier: 0")
        end
      end

      context "with the default assign_attributes (no subclass override)" do
        it "does not raise" do
          service = build_service(make_fake_find_service(success: true, record: make_fake_record(save_result: true)))
          expect { service.call }.not_to raise_error
        end
      end
    end
  end
end
