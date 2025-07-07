class CheckAdjustmentJob < ApplicationJob
  queue_as :background

  def perform(user)
    message = Message.build(user:, body: "You adjusted the content you receive from us a few weeks ago. How is it going? If it's good, no need to do anything. If you'd like to change it, text back 'ADJUST' to start the process again.")

    if message.save
      SendCustomMessageJob.perform_later(message)
    end
  end
end
