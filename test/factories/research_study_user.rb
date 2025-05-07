FactoryBot.define do
  factory :research_study_user do
    sequence(:last_four_digits_phone_number) { |n| "07" + n.to_s.rjust(2, "0") }
    postcode { "ABC123" }
  end
end
