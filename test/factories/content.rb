FactoryBot.define do
  factory :content do
    body { "Sample Body" }
    link { "www.example.com" }
    age_in_months { 18 }
    sequence(:position) { |n| n }

    group
  end
end
