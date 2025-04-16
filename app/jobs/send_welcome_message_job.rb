class SendWelcomeMessageJob < ApplicationJob
  include Rails.application.routes.url_helpers
  include MessageVariableSubstitution

  queue_as :background

  def perform(user)
    message = Message.build do |m|
      m.token = m.send(:generate_token)
      m.user = user
      m.body = substitute_variables(I18n.t(".messages.welcome"), user)
    end

    if message.save
      Twilio::Client.new.send_message(message)
      Survey.trigger_for(user, message_count: 0)
    end
  end
end
