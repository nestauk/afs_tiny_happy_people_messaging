class SendFeedbackMessageJob < ApplicationJob
  queue_as :background

  def perform(user)
    message = Message.build do |m|
      m.token = m.send(:generate_token)
      m.user = user
      m.body = I18n.t(".messages.feedback")
    end

    if message.save
      SendCustomMessageJob.perform_later(message)
      user.update(asked_for_feedback: true)
    end
  end
end
