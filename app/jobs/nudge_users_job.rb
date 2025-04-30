class NudgeUsersJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :background

  def perform(user)
    message = Message.build(user:, body: "You've not interacted with any videos lately. You can text 'PAUSE' for a break or 'END' to stop them entirely.")

    if message.save
      SendCustomMessageJob.perform_later(message)
      user.update(nudged_at: Time.now)
    end
  end
end
