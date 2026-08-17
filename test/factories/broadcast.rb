FactoryBot.define do
  factory :broadcast do
    body_en { "Some body in English" }
    body_cy { "Some body in Welsh" }
    association :admin
    survey { nil }
    user_groups { [:welsh_pilot] }
    message_threshold { nil }
  end
end
