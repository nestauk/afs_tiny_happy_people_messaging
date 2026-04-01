FactoryBot.define do
  factory :survey_send do
    user
    survey
    sent_at { Time.zone.now }
  end
end
