FactoryBot.define do
  factory :user do
    username do
      "#{Faker::Name.first_name}#{Faker::Name.last_name}".downcase.gsub(/[^a-z]/, '').then do |u|
        u.length >= 5 ? u[0, 30] : "#{u}user"[0, 30]
      end
    end
    password { "password123" }
    password_confirmation { "password123" }
  end
end
