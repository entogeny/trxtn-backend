require "rails_helper"

module Base
  RSpec.describe CreateService do
    # A plain object responding to .new — no ActiveRecord involved.
    def make_fake_model(save_result:, error_messages: [])
      record_class = Class.new do
        define_method(:assign_attributes) { |*| }
        define_method(:save) { save_result }
        define_method(:errors) { Struct.new(:full_messages).new(error_messages) }
      end

      model = Object.new
      model.define_singleton_method(:new) { record_class.new }
      model
    end

    def build_service(fake_model)
      Class.new(described_class) do
        define_method(:model) { fake_model }
        private :model
      end.new
    end

    describe "#model" do
      it "raises MissingDefinitionError when not overridden" do
        expect { described_class.new.call }.to raise_error(MissingDefinitionError, /#model must be implemented/)
      end
    end

    describe "#call" do
      context "when the record saves successfully" do
        subject(:service) { build_service(make_fake_model(save_result: true)) }

        it "returns true" do
          expect(service.call).to be true
        end

        it "exposes the record in output" do
          service.call
          expect(service.output[:record]).not_to be_nil
        end
      end

      context "when the record fails to save" do
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

      context "with the default assign_attributes (no subclass override)" do
        it "does not raise" do
          service = build_service(make_fake_model(save_result: true))
          expect { service.call }.not_to raise_error
        end
      end
    end

    describe "#validate" do
      it "is a no-op by default" do
        service = build_service(make_fake_model(save_result: true))
        expect { service.call }.not_to raise_error
      end

      context "when overridden in a subclass" do
        it "is called during #call" do
          validated = false
          fake_model = make_fake_model(save_result: true)

          service = Class.new(described_class) do
            define_method(:model) { fake_model }
            define_method(:validate) { validated = true }
            private :model, :validate
          end.new

          service.call
          expect(validated).to be true
        end
      end
    end
  end
end
