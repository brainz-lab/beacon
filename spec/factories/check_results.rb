FactoryBot.define do
  factory :check_result do
    association :uptime_monitor
    checked_at      { Time.current }
    region          { "us-east-1" }
    status          { "up" }
    response_time_ms { 120 }

    trait :up do
      status           { "up" }
      response_time_ms { 100 }
    end

    trait :down do
      status           { "down" }
      response_time_ms { nil }
      error_type       { "timeout" }
      error_message    { "Request timed out" }
    end

    trait :timeout do
      status        { "down" }
      error_type    { "timeout" }
      error_message { "Request timed out" }
    end

    trait :dns_error do
      status        { "down" }
      error_type    { "dns_error" }
      error_message { "DNS resolution failed" }
    end

    trait :ssl_error do
      status        { "down" }
      error_type    { "ssl_error" }
      error_message { "SSL certificate expired" }
    end

    trait :connection_refused do
      status        { "down" }
      error_type    { "connection_refused" }
      error_message { "Connection refused" }
    end

    trait :slow do
      status           { "up" }
      response_time_ms { 5000 }
    end

    trait :in_eu do
      region { "eu-west-1" }
    end
  end
end
