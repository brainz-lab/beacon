FactoryBot.define do
  factory :incident_update do
    incident
    status     { "investigating" }
    message    { "We are investigating the issue." }
    created_by { "system" }

    trait :human do
      created_by { "ops@example.com" }
      status     { "identified" }
      message    { "We have identified the root cause." }
    end

    trait :resolved do
      status     { "resolved" }
      message    { "The issue has been resolved." }
      created_by { "system" }
    end

    trait :monitoring do
      status  { "monitoring" }
      message { "Fix deployed. Monitoring for stability." }
    end
  end
end
