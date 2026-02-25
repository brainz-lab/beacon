FactoryBot.define do
  factory :uptime_monitor do
    project
    sequence(:name) { |n| "Monitor #{n}" }
    monitor_type        { "http" }
    url                 { "https://example.com" }
    interval_seconds    { 60 }
    timeout_seconds     { 30 }
    enabled             { true }
    paused              { false }
    status              { "unknown" }
    regions             { [ "us-east-1" ] }
    consecutive_failures  { 0 }
    consecutive_successes { 0 }
    confirmation_threshold { 2 }
    recovery_threshold     { 2 }

    trait :http do
      monitor_type { "http" }
      url          { "https://example.com" }
    end

    trait :tcp do
      monitor_type { "tcp" }
      url          { nil }
      host         { "db.example.com" }
      port         { 5432 }
    end

    trait :dns do
      monitor_type { "dns" }
      url          { nil }
      host         { "example.com" }
    end

    trait :ssl do
      monitor_type { "ssl" }
      url          { "https://example.com" }
    end

    trait :ping do
      monitor_type { "ping" }
      url          { nil }
      host         { "example.com" }
    end

    trait :up do
      status { "up" }
    end

    trait :down do
      status { "down" }
    end

    trait :degraded do
      status { "degraded" }
    end

    trait :paused do
      paused { true }
    end

    trait :disabled do
      enabled { false }
    end

    trait :with_ssl_expiry do
      ssl_expiry_at       { 20.days.from_now }
      ssl_expiry_warn_days { 30 }
    end
  end
end
