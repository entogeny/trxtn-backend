FactoryBot.define do
  factory :user do
    username { Faker::Internet.unique.username(specifier: 3..30, separators: []) }
    password { "password123" }
    password_confirmation { "password123" }
  end
end
