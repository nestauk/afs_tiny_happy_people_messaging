class RestartMessagesJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :background

  def perform(user)
    if user.update(contactable: true, restart_at: nil)
      url = edit_user_url(user, token: user.generate_token_for(:profile_token))

      message = Message.build(user: user, body: I18n.t(".messages.restart", locale: user.language).gsub("{{registration_form}}", url))
      SendCustomMessageJob.perform_later(message) if message.save
    end
  end
end
