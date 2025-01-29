FactoryBot.define do
  factory :auto_response do
    trigger_phrase { "pause" }
    response { "Thanks, we've paused" }
    update_user { "{}" }
    conditions { "{}" }
  end
end
