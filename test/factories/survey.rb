FactoryBot.define do
  factory :survey do
    sequence(:title) { |n| "Survey #{n}" }
  end
end
