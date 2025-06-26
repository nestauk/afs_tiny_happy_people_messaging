FactoryBot.define do
  factory :content_age_group do
    description { "Tiny elephant" }
    min_months { 3 }
    max_months { 6 }
  end
end
