FactoryBot.define do
  factory :event do
    description { Faker::Lorem.paragraph }
    name        { Faker::Commerce.product_name }
    start_at    { rand(1..90).days.from_now }
    end_at      { nil }
    owner       { nil }
    creator     { nil }

    trait :with_end_time do
      after(:build) do |event|
        event.end_at = event.start_at + rand(1..4).hours
      end
    end

    trait :with_owner do
      association :owner, factory: :user
      after(:build) do |event|
        event.creator      = event.owner
        event.creator_type = "User"
      end
    end
  end
end
