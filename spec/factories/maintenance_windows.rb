FactoryBot.define do
  factory :maintenance_window do
    project
    sequence(:title) { |n| "Maintenance Window #{n}" }
    starts_at            { 1.hour.from_now }
    ends_at              { 3.hours.from_now }
    status               { "scheduled" }
    affects_all_monitors { false }
    monitor_ids          { [] }
    notify_subscribers   { false }

    trait :active_now do
      starts_at { 30.minutes.ago }
      ends_at   { 2.hours.from_now }
      status    { "in_progress" }
    end

    trait :past do
      starts_at { 4.hours.ago }
      ends_at   { 2.hours.ago }
      status    { "completed" }
    end

    trait :in_progress do
      starts_at { 30.minutes.ago }
      ends_at   { 2.hours.from_now }
      status    { "in_progress" }
    end

    trait :cancelled do
      status { "cancelled" }
    end

    trait :all_monitors do
      affects_all_monitors { true }
    end

    trait :notify do
      notify_subscribers       { true }
      notify_before_minutes    { 30 }
    end
  end
end
