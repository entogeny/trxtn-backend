require "rails_helper"

module Base
  RSpec.describe UpdateService do
    # A plain object responding to .find — no ActiveRecord involved.
    def make_fake_model(save_result:, error_messages: [], raise_not_found: false)
      record_class = Class.new do
        define_method(:assign_attributes) { |*| }
        define_method(:save) { save_result }
        define_method(:errors) { Struct.new(:full_messages).new(error_messages) }
      end

      model = Object.new
      if raise_not_found
        model.define_singleton_method(:find) { |_id| raise ActiveRecord::RecordNotFound }
      else
        model.define_singleton_method(:find) { |_id| record_class.new }
      end
      model
    end

    def build_service(fake_model, id: 1)
      Class.new(described_class) do
        define_method(:model) { fake_model }
        private :model
      end.new(id: id)
    end

    describe "#model" do
      it "raises MissingDefinitionError when not overridden" do
        expect { described_class.new(id: 1).call }.to raise_error(MissingDefinitionError, /#model must be implemented/)
      end
    end

    describe "#call" do
      context "when the record is found and saves successfully" do
        subject(:service) { build_service(make_fake_model(save_result: true)) }

        it "returns true" do
          expect(service.call).to be true
        end

        it "exposes the record in output" do
          service.call
          expect(service.output[:record]).not_to be_nil
        end
      end

      context "when the record is found but fails to save" do
        subject(:service) do
          build_service(make_fake_model(save_result: false, error_messages: [ "Name can't be blank" ]))
        end

        it "returns false" do
          expect(service.call).to be false
        end

        it "populates errors from the record's validation messages" do
          service.call
          expect(service.errors.map { |e| e[:message] }).to include("Name can't be blank")
        end
      end

      context "when the record is not found" do
        it "raises ActiveRecord::RecordNotFound" do
          service = build_service(make_fake_model(save_result: false, raise_not_found: true))
          expect { service.call }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "with the default assign_attributes (no subclass override)" do
        it "does not raise" do
          service = build_service(make_fake_model(save_result: true))
          expect { service.call }.not_to raise_error
        end
      end
    end
  end
end
