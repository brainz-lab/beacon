FactoryBot.define do
  factory :ssl_certificate do
    association :uptime_monitor
    domain               { "example.com" }
    issuer               { "CN=Let's Encrypt Authority X3, O=Let's Encrypt, C=US" }
    subject              { "CN=example.com" }
    issued_at            { 60.days.ago }
    expires_at           { 90.days.from_now }
    valid                { true }
    last_checked_at      { Time.current }

    trait :valid_cert do
      expires_at { 90.days.from_now }
      valid      { true }
    end

    trait :expiring_soon do
      expires_at { 20.days.from_now }
    end

    trait :critical do
      expires_at { 5.days.from_now }
    end

    trait :expired do
      expires_at { 1.day.ago }
      valid      { false }
    end

    trait :invalid do
      valid { false }
    end
  end
end
