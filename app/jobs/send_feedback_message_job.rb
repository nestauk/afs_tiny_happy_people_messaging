class SendFeedbackMessageJob < ApplicationJob
  queue_as :background

  def perform(user)
    message = Message.build do |m|
      m.token = m.send(:generate_token)
      m.user = user
      m.body = "Are the activities we send you suitable for your child? Respond 'Yes' or 'No' to let us know."
    end

    if message.save
      SendCustomMessageJob.perform_later(message)
      user.content_adjustments.create
      user.update(asked_for_feedback: true)
    end
  end
end
