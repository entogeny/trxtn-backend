require "rails_helper"

RSpec.describe Api::Rest::V1::Concerns::Errorable do
  let(:test_class) do
    Class.new(ActionController::Base) do
      include Api::Rest::V1::Concerns::Errorable

      attr_reader :last_render_args

      def render(**kwargs)
        @last_render_args = kwargs
      end
    end
  end

  subject(:instance) { test_class.new }

  describe "#render_errors_json" do
    it "renders with status :internal_server_error by default" do
      instance.render_errors_json
      expect(instance.last_render_args[:status]).to eq(:internal_server_error)
    end

    it "renders an errors key in the response body" do
      instance.render_errors_json
      expect(instance.last_render_args[:json]).to have_key(:errors)
    end

    it "passes the errors array through to the response body" do
      errors = [ { message: "something went wrong" } ]
      instance.render_errors_json(errors)
      expect(instance.last_render_args[:json][:errors]).to eq(errors)
    end

    it "renders an empty errors array when none are provided" do
      instance.render_errors_json
      expect(instance.last_render_args[:json][:errors]).to eq([])
    end

    it "respects an explicit status override" do
      instance.render_errors_json([], status: :not_found)
      expect(instance.last_render_args[:status]).to eq(:not_found)
    end
  end

  describe "#handle_exception" do
    let(:exception) { StandardError.new("something broke") }

    it "renders the exception message wrapped in an array" do
      instance.send(:handle_exception, exception)
      expect(instance.last_render_args[:json][:errors]).to eq([ "something broke" ])
    end

    it "uses the default status when none is provided" do
      instance.send(:handle_exception, exception)
      expect(instance.last_render_args[:status]).to eq(:internal_server_error)
    end

    it "passes the status through to render_errors_json" do
      instance.send(:handle_exception, exception, status: :not_found)
      expect(instance.last_render_args[:status]).to eq(:not_found)
    end
  end
end
