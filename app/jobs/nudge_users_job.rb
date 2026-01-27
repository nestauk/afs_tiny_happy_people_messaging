class NudgeUsersJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :background

  def perform(user)
    message = Message.build(user:, body: I18n.t(".messages.nudge", locale: user.language || I18n.default_locale))

    if message.save
      SendCustomMessageJob.perform_later(message)
      user.update(nudged_at: Time.zone.now)
    end
  end
end
