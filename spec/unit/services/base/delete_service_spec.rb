require "rails_helper"

module Base
  RSpec.describe DeleteService do
    def make_fake_model(destroy_result:, error_messages: [], raise_not_found: false)
      record_class = Class.new do
        define_method(:destroy) { destroy_result }
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
      context "when the record is found and destroys successfully" do
        subject(:service) { build_service(make_fake_model(destroy_result: true)) }

        it "returns true" do
          expect(service.call).to be true
        end

        it "exposes the destroyed record in output" do
          service.call
          expect(service.output[:record]).not_to be_nil
        end
      end

      context "when the record is found but fails to destroy" do
        subject(:service) do
          build_service(make_fake_model(destroy_result: false, error_messages: [ "Cannot delete record" ]))
        end

        it "returns false" do
          expect(service.call).to be false
        end

        it "populates errors from the record's messages" do
          service.call
          expect(service.errors.map { |e| e[:message] }).to include("Cannot delete record")
        end
      end

      context "when the record is not found" do
        it "raises ActiveRecord::RecordNotFound" do
          service = build_service(make_fake_model(destroy_result: false, raise_not_found: true))
          expect { service.call }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end
