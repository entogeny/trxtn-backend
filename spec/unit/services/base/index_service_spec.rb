require "rails_helper"

module Base
  RSpec.describe IndexService do
    # A minimal fake ActiveRecord-like model that supports .all, .page, .per
    def make_fake_model(records:)
      page_class = Class.new do
        define_method(:initialize) { |recs| @recs = recs }
        define_method(:per) { |_n| @recs }
        define_method(:to_a) { @recs }
      end

      relation_class = Class.new do
        define_method(:initialize) { |recs| @recs = recs }
        define_method(:page) { |_n| page_class.new(@recs) }
      end

      model = Object.new
      model.define_singleton_method(:all) { relation_class.new(records) }
      model.define_singleton_method(:include?) { |_mod| false }
      model
    end

    def build_service(fake_model, input = {})
      Class.new(described_class) do
        define_method(:model) { fake_model }
        private :model
      end.new(input)
    end

    describe "#model" do
      it "raises MissingDefinitionError when not overridden" do
        expect { described_class.new.call }.to raise_error(MissingDefinitionError, /#model must be implemented/)
      end
    end

    describe "#call" do
      let(:fake_records) { [ double("record1"), double("record2") ] }
      subject(:service) { build_service(make_fake_model(records: fake_records)) }

      it "returns true" do
        expect(service.call).to be true
      end

      it "exposes records in output" do
        service.call
        expect(service.output[:records]).to eq(fake_records)
      end

      it "does not set output before call" do
        expect(service.output).to eq({})
      end

      context "with search params" do
        it "makes search_params available to a search override" do
          captured = nil
          fake = make_fake_model(records: [])
          service = Class.new(described_class) do
            define_method(:model) { fake }
            define_method(:search) { captured = search_params }
            private :model, :search
          end.new(search: { query: "test" })
          service.call
          expect(captured).to eq({ query: "test" })
        end
      end

      context "with filter params" do
        it "makes filter_params available to a filter override" do
          captured = nil
          fake = make_fake_model(records: [])
          service = Class.new(described_class) do
            define_method(:model) { fake }
            define_method(:filter) { captured = filter_params }
            private :model, :filter
          end.new(filter: { active: true })
          service.call
          expect(captured).to eq({ active: true })
        end
      end
    end
  end
end
