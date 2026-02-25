FactoryBot.define do
  factory :incident do
    association :uptime_monitor
    title       { "Service is down" }
    status      { "investigating" }
    severity    { "major" }
    started_at  { Time.current }
    affected_regions { [ "us-east-1" ] }

    # Skip the after_create notification job callback in factory
    after(:build) do |incident|
      incident.define_singleton_method(:schedule_notification) {}
    end

    trait :investigating do
      status { "investigating" }
    end

    trait :identified do
      status      { "identified" }
      identified_at { 10.minutes.ago }
    end

    trait :monitoring do
      status { "monitoring" }
    end

    trait :resolved do
      status           { "resolved" }
      resolved_at      { Time.current }
      duration_seconds { 3600 }
      resolution_notes { "Root cause identified and fixed" }
    end

    trait :minor do
      severity { "minor" }
    end

    trait :major do
      severity { "major" }
    end

    trait :critical do
      severity { "critical" }
      title    { "Critical outage detected" }
    end
  end
end
