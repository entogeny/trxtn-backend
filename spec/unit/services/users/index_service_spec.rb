require "rails_helper"

module Users
  RSpec.describe IndexService do
    def index(input = {})
      service = described_class.new(input)
      service.call
      service
    end

    describe "#call" do
      context "with no users" do
        it "returns true" do
          expect(index.success?).to be true
        end

        it "outputs an empty collection" do
          service = index
          expect(service.output[:records].to_a).to be_empty
        end
      end

      context "with multiple users" do
        let!(:users) { create_list(:user, 3) }

        it "returns true" do
          expect(index.success?).to be true
        end

        it "outputs all users" do
          service = index
          expect(service.output[:records].to_a).to match_array(users)
        end
      end

      context "with pagination" do
        before { create_list(:user, 15) }

        it "respects page_size" do
          service = index(pagination: { page_number: 1, page_size: 5 })
          expect(service.output[:records].to_a.length).to eq(5)
        end

        it "returns the correct page" do
          all_users = User.all.to_a
          service_page1 = index(pagination: { page_number: 1, page_size: 5 })
          service_page2 = index(pagination: { page_number: 2, page_size: 5 })
          expect(service_page1.output[:records].to_a).not_to eq(service_page2.output[:records].to_a)
        end

        it "falls back to default page_size when not specified" do
          service = index
          expect(service.output[:records].to_a.length).to eq(Base::IndexService::PAGINATION_DEFAULTS[:page_size])
        end
      end
    end
  end
end
