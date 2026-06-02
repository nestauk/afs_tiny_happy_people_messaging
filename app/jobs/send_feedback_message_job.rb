class SendFeedbackMessageJob < ApplicationJob
  queue_as :background

  def perform(user)
    message = Message.build do |m|
      m.user = user
      m.body = I18n.t(".messages.feedback", locale: user.language || I18n.default_locale)
    end

    if message.save
      SendCustomMessageJob.perform_later(message)
      user.update(asked_for_feedback: true)
    else
      Appsignal.report_error(StandardError.new("Failed to send feedback message")) do
        Appsignal.add_tags(user_id: user.id, errors: message.errors.full_messages)
      end
    end
  end
end
