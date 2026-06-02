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
    else
      Appsignal.report_error(StandardError.new("Failed to send welcome message")) do
        Appsignal.add_tags(user_id: user.id, errors: message.errors.full_messages)
      end
    end
  end
end
