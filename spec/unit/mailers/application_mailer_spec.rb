require "rails_helper"

RSpec.describe ApplicationMailer do
  it "inherits from ActionMailer::Base" do
    expect(described_class.superclass).to eq(ActionMailer::Base)
  end

  it "sends from the configured default address" do
    expect(described_class.default_params[:from]).to eq("from@example.com")
  end

  it "uses the mailer layout" do
    expect(described_class._layout).to eq("mailer")
  end
end
