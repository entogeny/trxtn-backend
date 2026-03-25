require "rails_helper"

module Base
  RSpec.describe SaveService do
    def make_fake_record(save_result:, error_messages: [])
      Class.new do
        define_method(:save) { save_result }
        define_method(:errors) { Struct.new(:full_messages).new(error_messages) }
      end.new
    end

    describe "#call" do
      context "when the record saves successfully" do
        subject(:service) { described_class.new(record: make_fake_record(save_result: true)) }

        it "returns true" do
          expect(service.call).to be true
        end

        it "exposes the record in output" do
          service.call
          expect(service.output[:record]).not_to be_nil
        end

        it "has no errors" do
          service.call
          expect(service.errors).to be_empty
        end
      end

      context "when the record fails to save" do
        subject(:service) do
          described_class.new(record: make_fake_record(save_result: false, error_messages: [ "Name can't be blank", "Email is invalid" ]))
        end

        it "returns false" do
          expect(service.call).to be false
        end

        it "populates one error per validation message" do
          service.call
          expect(service.errors.map { |e| e[:message] }).to contain_exactly("Name can't be blank", "Email is invalid")
        end
      end
    end
  end
end
