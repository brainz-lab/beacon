FactoryBot.define do
  factory :status_subscription do
    status_page
    channel         { "email" }
    email           { "user@example.com" }
    confirmed       { false }
    severity_filter { %w[minor major critical] }

    trait :email do
      channel { "email" }
      email   { "alerts@example.com" }
    end

    trait :sms do
      channel { "sms" }
      email   { nil }
      phone   { "+15550000001" }
    end

    trait :webhook do
      channel     { "webhook" }
      email       { nil }
      webhook_url { "https://hooks.example.com/notify" }
    end

    trait :confirmed do
      confirmed          { true }
      confirmed_at       { Time.current }
      confirmation_token { nil }
    end

    trait :pending do
      confirmed { false }
    end
  end
end
