class SendWelcomeMessageJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :default

  def perform(user)
    group = Group.find_by(age_in_months: user.child_age_in_months_today)

    message = if group.present? && group.welcome_message.present?
      Message.create do |m|
        m.token = m.send(:generate_token)
        m.link = group.welcome_message.link
        m.user = user
        m.body = group.welcome_message.body.gsub("{{link}}", track_link_url(m.token))
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
