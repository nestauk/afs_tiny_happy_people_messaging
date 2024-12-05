class SendWelcomeMessageJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :default

  def perform(user)
    content = Content.find_by(age_in_months: user.child_age_in_months_today, welcome_message: true)

    message = if content.present?
      Message.create do |m|
        m.token = m.send(:generate_token)
        m.link = content.link
        m.user = user
        m.body = content.body.gsub("{{link}}", track_link_url(m.token))
      end
    else
      Message.create do |m|
        m.token = m.send(:generate_token)
        m.user = user
        m.body = "Welcome to Tiny Happy People, a programme of weekly texts with fun activities! You'll receive your first activity soon."
      end
    end

    Twilio::Client.new.send_message(message)
  end
end
