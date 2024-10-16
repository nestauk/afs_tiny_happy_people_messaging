class SendWelcomeMessageJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :default

  WELCOME_VIDEOS = {
    17 => "https://www.bbc.co.uk/tiny-happy-people/tools-for-talking-18-24-months/zxdfp4j",
    18 => "https://www.bbc.co.uk/tiny-happy-people/shopping-game-18-24/zbhyf4j",
    19 => "https://www.bbc.co.uk/tiny-happy-people/how-to-make-a-ball-run/z4kk8xs",
    20 => "https://www.bbc.co.uk/tiny-happy-people/articles/znqqqp3",
    21 => "https://www.bbc.co.uk/tiny-happy-people/puppet-play-18-24/zj2ht39",
    22 => "https://www.bbc.co.uk/tiny-happy-people/lets-play-chefs/z762mfr",
    23 => "https://www.bbc.co.uk/tiny-happy-people/mealtime-challenge/zp3wcmn"
  }

  def perform(user)
    message = Message.create do |m|
      m.token = m.send(:generate_token)
      m.link = WELCOME_VIDEOS[user.child_age_in_months_today]
      m.user = user
      m.body = "Welcome to our programme of weekly texts with fun activities! Here's a video to get you started: #{track_link_url(m.token)}"
    end

    Twilio::Client.new.send_message(message)
  end
end
