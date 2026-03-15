require "rails_helper"

module Auth
  module AccessTokens
    RSpec.describe EncodeService do
      describe ".call" do
        it "returns a JWT string" do
          token = described_class.call({ sub: 42 })
          expect(token).to be_a(String)
          expect(token.split(".").length).to eq(3)
        end

        it "embeds the sub claim" do
          token = described_class.call({ sub: 42 })
          payload = JWT.decode(token, Rails.application.credentials.jwt_secret_key!, true, algorithm: "HS256").first
          expect(payload["sub"]).to eq(42)
        end

        it "sets an exp claim approximately 1 hour from now" do
          freeze_time = Time.current
          allow(Time).to receive(:current).and_return(freeze_time)

          token = described_class.call({ sub: 1 })
          payload = JWT.decode(token, Rails.application.credentials.jwt_secret_key!, true, algorithm: "HS256").first

          expect(payload["exp"]).to be_within(5).of(1.hour.from_now.to_i)
        end
      end
    end
  end
end
