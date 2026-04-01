FactoryBot.define do
  factory :event do
    description { Faker::Lorem.paragraph }
    name        { Faker::Commerce.product_name }
    start_at    { rand(1..90).days.from_now }
    end_at      { nil }

    trait :with_end_time do
      after(:build) do |event|
        event.end_at = event.start_at + rand(1..4).hours
      end
    end
  end
end
