class SendWelcomeMessageJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :default

  WELCOME_VIDEOS = {
    17 => "https://www.youtube.com/watch?v=3p6h9f1qk8k",
    18 => "https://www.youtube.com/watch?v=3p6h9f1qk8k",
    19 => "https://www.youtube.com/watch?v=3p6h9f1qk8k",
    20 => "https://www.youtube.com/watch?v=3p6h9f1qk8k",
    21 => "https://www.youtube.com/watch?v=3p6h9f1qk8k",
    22 => "https://www.youtube.com/watch?v=3p6h9f1qk8k",
    23 => "https://www.youtube.com/watch?v=3p6h9f1qk8k",
    24 => "https://www.youtube.com/watch?v=3p6h9f1qk8k"
  }

  def perform(user)
    message = Message.create do |m|
      m.token = m.send(:generate_token)
      m.link = WELCOME_VIDEOS[user.child_age_in_months_today]
      m.user = user
      m.body = "Hi #{user.first_name}, welcome to Tiny Happy People. Here's a video to get you started: #{track_link_url(m.token)}"
    end

    Twilio::Client.new.send_message(message)
  end
end
