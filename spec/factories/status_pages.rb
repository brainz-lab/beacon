FactoryBot.define do
  factory :status_page do
    project
    sequence(:name) { |n| "Status Page #{n}" }
    # slug generated from name by before_validation callback
    public              { true }
    current_status      { "operational" }
    allow_subscriptions { true }
    show_uptime         { true }
    show_response_time  { true }
    show_incidents      { true }
    uptime_days_shown   { 90 }

    trait :private do
      public { false }
    end

    trait :major_outage do
      current_status { "major_outage" }
    end

    trait :degraded do
      current_status { "degraded" }
    end

    trait :partial_outage do
      current_status { "partial_outage" }
    end

    trait :with_custom_slug do
      slug { "my-custom-status" }
    end
  end
end
