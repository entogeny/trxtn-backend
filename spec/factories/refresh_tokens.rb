FactoryBot.define do
  factory :refresh_token do
    association :user
    token_digest { Digest::SHA256.hexdigest(SecureRandom.hex(32)) }
    expires_at { 90.days.from_now }
    revoked_at { nil }

    trait :revoked do
      revoked_at { 1.hour.ago }
    end

    trait :expired do
      expires_at { 1.hour.ago }
    end
  end
end
