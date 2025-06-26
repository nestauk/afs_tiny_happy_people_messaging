FactoryBot.define do
  factory :auto_response do
    trigger_phrase { "pause" }
    response { "Thanks, we've paused" }
    update_user { "{}" }
    user_conditions { "{}" }
    content_adjustment_conditions { "{}" }
    update_content_adjustment { "{}" }
  end
end
