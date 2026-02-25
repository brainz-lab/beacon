FactoryBot.define do
  factory :status_page_monitor do
    status_page
    association :uptime_monitor
    visible  { true }
    position { 1 }

    trait :invisible do
      visible { false }
    end

    trait :with_display_name do
      display_name { "Custom Display Name" }
    end

    trait :grouped do
      group_name { "Core Services" }
    end
  end
end
