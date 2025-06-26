FactoryBot.define do
  factory :content_age_group do
    description { "Tiny elephant" }
    min_months { 7 }
    max_months { 9 }
  end
end
