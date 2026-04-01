FactoryBot.define do
  factory :survey do
    sequence(:title_en) { |n| "Survey #{n}" }
    sequence(:title_cy) { |n| "Arolwg #{n}" }
  end
end
