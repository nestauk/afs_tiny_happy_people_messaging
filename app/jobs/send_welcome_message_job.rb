class SendWelcomeMessageJob < ApplicationJob
  include Rails.application.routes.url_helpers
  include MessageVariableSubstitution

  queue_as :background

  def perform(user)
    message = Message.build do |m|
      m.token = m.send(:generate_token)
      m.user = user
      m.body = substitute_variables(Content::WELCOME_MESSAGE, user)
    end

    Twilio::Client.new.send_message(message) if message.save
  end
end
