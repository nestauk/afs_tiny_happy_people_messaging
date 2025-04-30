class NudgeUsersJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :background

  def perform(user)
    if user.update(contactable: true)
      message = Message.create(user:, body: "You've not interacted with any videos lately. You can text 'PAUSE' for a break or 'END' to stop them entirely.")
      SendCustomMessageJob.perform_later(message)
      user.update(nudged_at: Time.now)
    end
  end
end
