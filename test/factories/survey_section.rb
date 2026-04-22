FactoryBot.define do
  factory :survey_section do
    sequence(:title_en) { |n| "Section #{n}" }
    sequence(:title_cy) { |n| "Adran #{n}" }
    sequence(:position) { |n| n }
    survey
  end
end
