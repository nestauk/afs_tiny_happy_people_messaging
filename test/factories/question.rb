FactoryBot.define do
  factory :question do
    sequence(:text_en) { |n| "Question #{n}" }
    sequence(:text_cy) { |n| "Cwestiwn #{n}" }
    sequence(:position) { |n| n }
    question_type { "text" }
    survey

    trait :check_boxes do
      question_type { "check_boxes" }
      options_en { ["Option A", "Option B", "Option C"] }
      options_cy { ["Opsiwn A", "Opsiwn B", "Opsiwn C"] }
    end

    trait :radio_buttons do
      question_type { "radio_buttons" }
      options_en { ["Yes", "No"] }
      options_cy { ["Ie", "Na"] }
    end
  end
end
