FactoryBot.define do
  factory :question do
    sequence(:text) { |n| "Question #{n}" }
    sequence(:position) { |n| n }
    question_type { "text" }
    survey

    trait :check_boxes do
      question_type { "check_boxes" }
      options { ["Option A", "Option B", "Option C"] }
    end

    trait :radio_buttons do
      question_type { "radio_buttons" }
      options { ["Yes", "No"] }
    end
  end
end
