require "rails_helper"

module Base
  RSpec.describe FindService do
    def make_fake_model(record: nil, has_slug: false)
      found = record

      model = Object.new
      model.define_singleton_method(:find_by) { |attrs| attrs[:id] ? found : nil }
      model.define_singleton_method(:attribute_method?) { |_attr| has_slug }
      model.define_singleton_method(:include?) { |_mod| false }
      model.define_singleton_method(:all) { model }
      model
    end

    def build_service(fake_model, identifier:)
      Class.new(described_class) do
        define_method(:model) { fake_model }
        private :model
      end.new(identifier: identifier)
    end

    describe "#model" do
      it "raises MissingDefinitionError when not overridden" do
        expect { described_class.new(identifier: 1).call }.to raise_error(MissingDefinitionError, /#model must be implemented/)
      end
    end

    describe "#call" do
      context "when the record is found by id" do
        let(:fake_record) { Object.new }
        subject(:service) { build_service(make_fake_model(record: fake_record), identifier: 1) }

        it "returns true" do
          expect(service.call).to be true
        end

        it "exposes the record in output" do
          service.call
          expect(service.output[:record]).to eq(fake_record)
        end
      end

      context "when the record is found by slug" do
        let(:fake_record) { Object.new }
        let(:slug_model) do
          record = fake_record
          model = Object.new
          model.define_singleton_method(:find_by) { |attrs| attrs[:slug] ? record : nil }
          model.define_singleton_method(:attribute_method?) { |_| true }
          model.define_singleton_method(:include?) { |_mod| false }
          model.define_singleton_method(:all) { model }
          model
        end

        it "returns true" do
          service = build_service(slug_model, identifier: "some-slug")
          expect(service.call).to be true
        end

        it "exposes the record in output" do
          service = build_service(slug_model, identifier: "some-slug")
          service.call
          expect(service.output[:record]).to eq(fake_record)
        end
      end

      context "when the model has no slug attribute" do
        it "does not attempt slug lookup" do
          slug_called = false
          model = Object.new
          model.define_singleton_method(:find_by) do |attrs|
            if attrs[:slug]
              slug_called = true
            end
            nil
          end
          model.define_singleton_method(:attribute_method?) { |_| false }
          model.define_singleton_method(:include?) { |_mod| false }
          model.define_singleton_method(:all) { model }

          build_service(model, identifier: "some-slug").call

          expect(slug_called).to be false
        end
      end

      context "when the record is not found" do
        subject(:service) { build_service(make_fake_model(record: nil), identifier: 99) }

        it "returns false" do
          expect(service.call).to be false
        end

        it "adds an error referencing the identifier" do
          service.call
          expect(service.errors.first[:message]).to include("99")
        end
      end
    end
  end
end
