class ChaseAdjustmentJob < ApplicationJob
  queue_as :background

  def perform(user)
    message = Message.build(user:, body: "Do you still want to adjust your content? You can reply to the last adjustment message or text 'ADJUST' to start again. If you don't want to adjust the content, you don't need to do anything.")

    if message.save
      SendCustomMessageJob.perform_later(message)
    end
  end
end
