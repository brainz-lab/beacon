FactoryBot.define do
  factory :alert_rule do
    association :uptime_monitor
    sequence(:name) { |n| "Alert Rule #{n}" }
    condition_type   { "status_change" }
    condition_config { { "to" => "down" } }
    enabled          { true }
    notify_channels  { [] }

    trait :status_change do
      condition_type   { "status_change" }
      condition_config { { "from" => "up", "to" => "down" } }
    end

    trait :response_time do
      condition_type   { "response_time" }
      condition_config { { "operator" => "gt", "value" => 1000 } }
    end

    trait :ssl_expiry do
      condition_type   { "ssl_expiry" }
      condition_config { { "days_before" => 30 } }
    end

    trait :consecutive_failures do
      condition_type   { "consecutive_failures" }
      condition_config { { "count" => 3 } }
    end

    trait :uptime_percentage do
      condition_type   { "uptime_percentage" }
      condition_config { { "threshold" => 99.0, "period_days" => 7 } }
    end

    trait :disabled do
      enabled { false }
    end

    trait :with_channels do
      notify_channels { [ "signal", "email" ] }
    end
  end
end
