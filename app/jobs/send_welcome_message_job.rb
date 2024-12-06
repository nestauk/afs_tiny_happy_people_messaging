class SendWelcomeMessageJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :default

  def perform(user)
    message = Message.build do |m|
      m.token = m.send(:generate_token)
      m.user = user
      m.body = Content::WELCOME_MESSAGE
    end

    Twilio::Client.new.send_message(message) if message.save
  end
end
