FactoryBot.define do
  factory :article do
    association :user

    title { "MyString" }
    body { "MyText" }

    trait :hidden do
      hidden { true }
    end

    trait :published do
      published { true }
    end
  end
end
