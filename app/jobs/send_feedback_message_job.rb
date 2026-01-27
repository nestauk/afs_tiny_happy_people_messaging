class SendFeedbackMessageJob < ApplicationJob
  queue_as :background

  def perform(user)
    Appsignal::CheckIn.cron("send_feedback_message_job") do
      message = Message.build do |m|
        m.token = m.send(:generate_token)
        m.user = user
        m.body = I18n.t(".messages.feedback", locale: user.language || I18n.default_locale)
      end

      if message.save
        SendCustomMessageJob.perform_later(message)
        user.update(asked_for_feedback: true)
      end
    end
  end
end
