class RestartMessagesJob < ApplicationJob
  queue_as :background

  def perform(user)
    if user.update(contactable: true, restart_at: nil)
      message = Message.build(user: user, body: I18n.t(".messages.restart", locale: user.language || I18n.default_locale))
      SendCustomMessageJob.perform_later(message) if message.save
    end
  end
end
