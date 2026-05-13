class SendWelcomeMessageJob < ApplicationJob
  include Rails.application.routes.url_helpers
  include MessageVariableSubstitution

  queue_as :background

  def perform(user)
    message = Message.build do |m|
      m.user = user
      m.body = substitute_variables(I18n.t(".messages.welcome", locale: user.language), user)
    end

    if message.save
      Twilio::Client.new.send_message(message)
    end
  end
end
