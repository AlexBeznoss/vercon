ADMIN_USER_ID = rand(999..1_099_997)

FactoryBot.define do
  factory :user do
    sequence(:email) { |i| "#{i}-name@example.com" }

    role { "user" }

    trait :admin do
      sequence(:id) { |i| ADMIN_USER_ID * i }
      role { "admin" }
    end
  end
end
