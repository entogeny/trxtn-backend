require "rails_helper"

RSpec.describe Api::Rest::V1::Concerns::Serializable do
  let(:test_class) do
    Class.new do
      include Api::Rest::V1::Concerns::Serializable

      attr_reader :last_render_args

      def render(**kwargs)
        @last_render_args = kwargs
      end

      def params
        ActionController::Parameters.new({})
      end
    end
  end

  subject(:instance) { test_class.new }

  describe "#render_serialized_json" do
    let(:serializer) { double("serializer") }
    let(:data)       { double("data") }

    before do
      allow(serializer).to receive(:render).and_return("{}")
    end

    it "wraps the response under a :data root key by default" do
      instance.render_serialized_json(serializer, data)
      expect(serializer).to have_received(:render).with(data, hash_including(root: :data))
    end

    it "renders with view :standard by default" do
      instance.render_serialized_json(serializer, data)
      expect(serializer).to have_received(:render).with(data, hash_including(view: :standard))
    end

    it "renders with status :ok by default" do
      instance.render_serialized_json(serializer, data)
      expect(instance.last_render_args[:status]).to eq(:ok)
    end

    it "respects an explicit view option" do
      instance.render_serialized_json(serializer, data, { view: "extended" })
      expect(serializer).to have_received(:render).with(data, hash_including(view: :extended))
    end

    it "respects an explicit root option" do
      instance.render_serialized_json(serializer, data, { root: :results })
      expect(serializer).to have_received(:render).with(data, hash_including(root: :results))
    end

    it "passes meta through when provided" do
      meta = { total: 10 }
      instance.render_serialized_json(serializer, data, { meta: meta })
      expect(serializer).to have_received(:render).with(data, hash_including(meta: meta))
    end

    it "renders with an explicit status" do
      instance.render_serialized_json(serializer, data, {}, status: :created)
      expect(instance.last_render_args[:status]).to eq(:created)
    end
  end

  describe "#serialization_params" do
    context "when no serialization params are present" do
      it "defaults to view :standard" do
        expect(instance.serialization_params[:view]).to eq(:standard)
      end
    end

    context "when serialization[view] is provided" do
      before do
        allow(instance).to receive(:params).and_return(
          ActionController::Parameters.new({ serialization: { view: "extended" } })
        )
      end

      it "returns the client-supplied view" do
        expect(instance.serialization_params[:view]).to eq("extended")
      end
    end
  end
end
